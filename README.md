
Gaussian Blur for URP
===

![Example output](Example.jpg)

Optimized Gaussian blur function with configurable sigma and radius.

1. Play around with sigma and radius values to find the optimal parameters.
2. Replace the sigma and radius parameters with literal values to let the Unity shader compiler produce efficient code.
3. `#define GAUSSIAN_BLUR_UNROLL 1` before including this file.

Usage
---

Include this shader file (path may vary):
```hlsl
// #define GAUSSIAN_BLUR_UNROLL 1
#include "Assets/Shaders/GaussianBlur.hlsl"
```

### 2 Pass

It is highly recommended to use this variation if you have access to a temporary texture to ping-pong buffer.

The number of texture samples needed for each pass is radius + 1.

For example, a 5x5 kernel has a radius of 2, which means 3 texture samples are needed for each pass.

First pass:
```hlsl
return GaussianBlurHorizontal(_SourceTex, sampler_SourceTex, _SourceTex_TexelSize, i.uv, 1, 3);
```

Second pass:
```hlsl
return GaussianBlurVertical(_SourceTex, sampler_SourceTex, _SourceTex_TexelSize, i.uv, 1, 3);
```

### 1 Pass

This variant is used to perform Gaussian blur in a single pass. This is useful when it is not possible or is too difficult to prepare a temporary texture for the 2 pass approach.

The number of texture samples needed is `(radius + 1)^2`.

For example, a 5x5 kernel has a radius of 2, which means 9 texture samples are needed in this case.

This is significantly smaller than the naive implementation, which requires `(radius * 2 + 1)^2`, but still is an `O(n^2)` algorithm.

```hlsl
return GaussianBlurSingle(_SourceTex, sampler_SourceTex, _SourceTex_TexelSize, i.uv, 1, 2);
```

Why
---
I could no longer be bothered writing kernel calculation code on CPU, and pass parameters to the shader for experimenting with sigma and radius, so I wrote this to let the Unity shader compiler generate the code I want.

I also saw various implementations of unoptimized Gaussian blur in many places, which led me to write this.

Notes
---
- The function minimizes the texture fetches by bilinear filtering.
- The produced code will be more efficient if `GAUSSIAN_BLUR_UNROLL` is set. However, it won't compile if the radius parameter is not a literal value.
- UV calculations can be moved to vertex shader if further optimizations are required.
- Loop unroll will succeed even if the sigma parameter is dynamic. However, the generated code is not very efficient. It is desirable to move these weight calculations to the CPU.

Example Code Generated
---

### 2 Pass
- Vertical pass
- Sigma = 3
- Radius = 6

```glsl
u_xlat0.x = 0.0;
u_xlat0.y = _SourceTex_TexelSize.y;
u_xlat1 = vec4(-5.35180569, -5.35180569, -3.40398479, -3.40398479) * u_xlat0.xyxy + vs_TEXCOORD0.xyxy;
u_xlat16_2 = texture(_SourceTex, u_xlat1.zw);
u_xlat16_1 = texture(_SourceTex, u_xlat1.xy);
u_xlat2 = u_xlat16_2 * vec4(0.139440298, 0.139440298, 0.139440298, 0.139440298);
u_xlat1 = u_xlat16_1 * vec4(0.0527109653, 0.0527109653, 0.0527109653, 0.0527109653) + u_xlat2;
u_xlat2 = vec4(-1.45842957, -1.45842957, 1.45842957, 1.45842957) * u_xlat0.xyxy + vs_TEXCOORD0.xyxy;
u_xlat0 = vec4(3.40398479, 3.40398479, 5.35180569, 5.35180569) * u_xlat0.xyxy + vs_TEXCOORD0.xyxy;
u_xlat16_3 = texture(_SourceTex, u_xlat2.xy);
u_xlat16_2 = texture(_SourceTex, u_xlat2.zw);
u_xlat1 = u_xlat16_3 * vec4(0.239337295, 0.239337295, 0.239337295, 0.239337295) + u_xlat1;
u_xlat16_3 = texture(_SourceTex, vs_TEXCOORD0.xy);
u_xlat1 = u_xlat16_3 * vec4(0.137022808, 0.137022808, 0.137022808, 0.137022808) + u_xlat1;
u_xlat1 = u_xlat16_2 * vec4(0.239337295, 0.239337295, 0.239337295, 0.239337295) + u_xlat1;
u_xlat16_2 = texture(_SourceTex, u_xlat0.xy);
u_xlat16_0 = texture(_SourceTex, u_xlat0.zw);
u_xlat1 = u_xlat16_2 * vec4(0.139440298, 0.139440298, 0.139440298, 0.139440298) + u_xlat1;
u_xlat0 = u_xlat16_0 * vec4(0.0527109653, 0.0527109653, 0.0527109653, 0.0527109653) + u_xlat1;
SV_Target0 = u_xlat0;
```

### 1 Pass
- Sigma = 1
- Radius = 2

```glsl
u_xlat0 = _SourceTex_TexelSize.xyxy * vec4(-1.1824255, -1.1824255, 0.0, -1.1824255) + vs_TEXCOORD0.xyxy;
u_xlat16_1 = texture(_SourceTex, u_xlat0.zw);
u_xlat16_0 = texture(_SourceTex, u_xlat0.xy);
u_xlat1 = u_xlat16_1 * vec4(0.12025857, 0.12025857, 0.12025857, 0.12025857);
u_xlat0 = u_xlat16_0 * vec4(0.0892157406, 0.0892157406, 0.0892157406, 0.0892157406) + u_xlat1;
u_xlat1 = _SourceTex_TexelSize.xyxy * vec4(1.1824255, -1.1824255, -1.1824255, 0.0) + vs_TEXCOORD0.xyxy;
u_xlat16_2 = texture(_SourceTex, u_xlat1.xy);
u_xlat16_1 = texture(_SourceTex, u_xlat1.zw);
u_xlat0 = u_xlat16_2 * vec4(0.0892157406, 0.0892157406, 0.0892157406, 0.0892157406) + u_xlat0;
u_xlat0 = u_xlat16_1 * vec4(0.12025857, 0.12025857, 0.12025857, 0.12025857) + u_xlat0;
u_xlat16_1 = texture(_SourceTex, vs_TEXCOORD0.xy);
u_xlat0 = u_xlat16_1 * vec4(0.162102833, 0.162102833, 0.162102833, 0.162102833) + u_xlat0;
u_xlat1 = _SourceTex_TexelSize.xyxy * vec4(1.1824255, 0.0, -1.1824255, 1.1824255) + vs_TEXCOORD0.xyxy;
u_xlat16_2 = texture(_SourceTex, u_xlat1.xy);
u_xlat16_1 = texture(_SourceTex, u_xlat1.zw);
u_xlat0 = u_xlat16_2 * vec4(0.12025857, 0.12025857, 0.12025857, 0.12025857) + u_xlat0;
u_xlat0 = u_xlat16_1 * vec4(0.0892157406, 0.0892157406, 0.0892157406, 0.0892157406) + u_xlat0;
u_xlat1 = _SourceTex_TexelSize.xyxy * vec4(0.0, 1.1824255, 1.1824255, 1.1824255) + vs_TEXCOORD0.xyxy;
u_xlat16_2 = texture(_SourceTex, u_xlat1.xy);
u_xlat16_1 = texture(_SourceTex, u_xlat1.zw);
u_xlat0 = u_xlat16_2 * vec4(0.12025857, 0.12025857, 0.12025857, 0.12025857) + u_xlat0;
u_xlat0 = u_xlat16_1 * vec4(0.0892157406, 0.0892157406, 0.0892157406, 0.0892157406) + u_xlat0;
SV_Target0 = u_xlat0;
```
