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

#ifndef GAUSSIAN_BLUR_INCLUDED
#define GAUSSIAN_BLUR_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

inline float Gauss(float sigma, int x)
{
    return exp(-(x * x) / (2 * sigma * sigma));
}

inline float GaussianWeight(float sigma, int radius, int x)
{
    float sum = 0;
    UNITY_UNROLL
    for (int i = 0; i < radius * 2 + 1; i++)
    {
        sum += Gauss(sigma, i - radius);
    }
    float w = Gauss(sigma, x) / sum;
    UNITY_FLATTEN
    if (x == 0)
    {
        w *= 0.5;
    }
    return w;
}

// Separable Gaussian blur function with configurable sigma and radius.
//
// The delta parameter should be (texelSize.x, 0), and (0, texelSize.y) for each passes.
// This function is used to quickly play around with sigma and radius values to find the optimal parameters in
// development.
// Replacing the sigma and radius parameters with literal values lets the Unity shader compiler produce efficient code.
// Do NOT use this function if parameters must be configurable for the shipping product.
float4 GaussianBlur(TEXTURE2D_PARAM(tex, samplerTex), float2 delta, float2 uv, float sigma, int radius)
{
    int idx = -radius;
    float4 res = 0;

    // Exploit bilinear sampling to reduce the number of texture fetches, only requiring radius + 1 fetches.
    UNITY_UNROLL
    for (int i = 0; i < radius + 1; ++i)
    {
        const int x0 = idx;
        int x1 = x0 + 1;

        // Sample just the center texel if the radius is an even number
        UNITY_FLATTEN
        if ((radius & 1) == 0 && x0 == 0)
        {
            x1 = 0;
        }

        // Calculate the weights for each texel
        const float w0 = GaussianWeight(sigma, radius, x0);
        const float w1 = GaussianWeight(sigma, radius, x1);

        // Adjust the sampling position depending on the required weight.
        // Use bilinear sampling to fetch two texels at once.
        const float texelOffset = w1 / (w0 + w1);
        const float2 sampleUV = uv + (x0 + texelOffset) * delta;
        res += SAMPLE_TEXTURE2D(tex, samplerTex, sampleUV) * (w0 + w1);

        // Step to next sample
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

#endif
