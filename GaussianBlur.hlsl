// MIT License
//
// Copyright (c) 2021 Akihiro Noguchi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 
// Usage:
// 1. Play around with sigma and radius values to find the optimal parameters.
// 2. `#define GAUSSIAN_BLUR_UNROLL 1` before including this file.
// 3. Replace the sigma and radius parameters with literal values to let the Unity shader compiler produce efficient
//    code.
//
// Do NOT use this library as is if sigma must be configurable for the shipping product.
// Consider moving sigma calculation to CPU code in such case.

#ifndef GAUSSIAN_BLUR_INCLUDED
#define GAUSSIAN_BLUR_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

inline float Gauss(float sigma, int x)
{
    return exp(-(x * x) / (2 * sigma * sigma));
}

inline float Gauss(float sigma, int x, bool isHalf)
{
    return Gauss(sigma, x) * (isHalf ? 0.5 : 1);
}

inline float GaussianWeightSum1D(float sigma, int radius)
{
    float sum = 0;
    #if GAUSSIAN_BLUR_UNROLL
    UNITY_UNROLL
    #endif
    for (int i = 0; i < radius * 2 + 1; i++)
    {
        sum += Gauss(sigma, i - radius);
    }
    return sum;
}

inline float GaussianWeightSum2D(float sigma, int radius)
{
    const float baseSum = GaussianWeightSum1D(sigma, radius);
    float sum = 0;
    #if GAUSSIAN_BLUR_UNROLL
    UNITY_UNROLL
    #endif
    for (int i = 0; i < radius * 2 + 1; i++)
    {
        sum += Gauss(sigma, i - radius) * baseSum;
    }
    return sum;
}

// Separable Gaussian blur function with configurable sigma and radius.
//
// The delta parameter should be (texelSize.x, 0), and (0, texelSize.y) for each passes.
//
float4 GaussianBlurSeparable(TEXTURE2D_PARAM(tex, samplerTex), float2 delta, float2 uv, float sigma, int radius)
{
    int idx = -radius;
    float4 res = 0;

    const float totalWeightRcp = rcp(GaussianWeightSum1D(sigma, radius));

    // Exploit bilinear sampling to reduce the number of texture fetches, only requiring radius + 1 fetches.
    #if GAUSSIAN_BLUR_UNROLL
    UNITY_UNROLL
    #endif
    for (int i = 0; i < radius + 1; ++i)
    {
        const int x0 = idx;
        // Sample just the center texel if the radius is an even number
        const bool isNarrow = (radius & 1) == 0 && x0 == 0;
        const int x1 = isNarrow ? x0 : x0 + 1;

        // Calculate the weights for each texel
        const float w0 = Gauss(sigma, x0, x0 == 0);
        const float w1 = Gauss(sigma, x1, x1 == 0);

        // Adjust the sampling position depending on the required weight.
        // Use bilinear sampling to fetch two texels at once.
        const float texelOffset = isNarrow ? 0 : w1 / (w0 + w1);
        const float2 sampleUV = uv + (x0 + texelOffset) * delta;
        const float weight = (w0 + w1) * totalWeightRcp;
        res += SAMPLE_TEXTURE2D(tex, samplerTex, sampleUV) * weight;

        // Step to the next sample
        UNITY_FLATTEN
        if ((radius & 1) == 1 && x1 == 0)
        {
            idx = 0;
        }
        else
        {
            idx = x1 + 1;
        }
    }
    return res;
}

// Separable Gaussian blur function with configurable sigma and radius (horizontal pass)
float4 GaussianBlurHorizontal(TEXTURE2D_PARAM(tex, samplerTex), float2 delta, float2 uv, float sigma, int radius)
{
    return GaussianBlurSeparable(TEXTURE2D_ARGS(tex, samplerTex), float2(delta.x, 0), uv, sigma, radius);
}

// Separable Gaussian blur function with configurable sigma and radius (vertical pass)
float4 GaussianBlurVertical(TEXTURE2D_PARAM(tex, samplerTex), float2 delta, float2 uv, float sigma, int radius)
{
    return GaussianBlurSeparable(TEXTURE2D_ARGS(tex, samplerTex), float2(0, delta.y), uv, sigma, radius);
}

// Single pass Gaussian blur function with configurable sigma and radius.
//
// The delta parameter should be the texel size for the input texture.
float4 GaussianBlurSingle(TEXTURE2D_PARAM(tex, samplerTex), float2 delta, float2 uv, float sigma, int radius)
{
    float4 res = 0;

    const float totalWeightRcp = rcp(GaussianWeightSum2D(sigma, radius));

    int idxY = -radius;
    #if GAUSSIAN_BLUR_UNROLL
    UNITY_UNROLL
    #endif
    for (int i = 0; i < radius + 1; ++i)
    {
        const int y0 = idxY;
        // Narrow state represents a flag where a single pixel is sampled instead of two
        const bool isNarrowY = (radius & 1) == 0 && y0 == 0 || // Even radius means center texel is sampled alone
            (radius & 1) == 1 && y0 == radius; // Odd radius means rightmost center is sampled alone
        const int y1 = isNarrowY ? y0 : y0 + 1;

        int idxX = -radius;

        #if GAUSSIAN_BLUR_UNROLL
        UNITY_UNROLL
        #endif
        for (int j = 0; j < radius + 1; ++j)
        {
            const int x0 = idxX;
            const bool isNarrowX = (radius & 1) == 0 && x0 == 0 || (radius & 1) == 1 && x0 == radius;
            const int x1 = isNarrowX ? x0 : x0 + 1;

            // Weights in both directions
            const float wx0 = Gauss(sigma, x0, isNarrowX);
            const float wx1 = Gauss(sigma, x1, isNarrowX);
            const float wy0 = Gauss(sigma, y0, isNarrowY);
            const float wy1 = Gauss(sigma, y1, isNarrowY);

            // Adjust the sampling position depending on the required weight.
            // Use bilinear sampling to fetch four texels at once if possible.
            const float2 texelOffset = float2(isNarrowX ? 0 : wx1 / (wx0 + wx1), isNarrowY ? 0 : wy1 / (wy0 + wy1));
            const float2 sampleUV = uv + (float2(x0, y0) + texelOffset) * delta;

            // Sum the weights of four texels, and normalize
            const float weight = ((wx0 + wx1) * wy0 + (wx0 + wx1) * wy1) * totalWeightRcp;
            res += SAMPLE_TEXTURE2D(tex, samplerTex, sampleUV) * weight;

            // Step to the next sample
            idxX = x1 + 1;
        }

        // Step to the next sample
        idxY = y1 + 1;
    }
    return res;
}

#endif
