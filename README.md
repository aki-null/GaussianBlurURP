Separable Gaussian Blur for URP
===

![Example output](Example.jpg)

Separable Gaussian blur function with configurable sigma and radius.

1. Play around with sigma and radius values to find the optimal parameters.
2. Replace the sigma and radius parameters with literal values to let the Unity shader compiler produce efficient code.
3. `#define GAUSSIAN_BLUR_UNROLL 1` before including this file.

Do NOT use this function if parameters are dynamic for the shipping product.

Usage
---

Include this shader file (path may vary):
```hlsl
// #define GAUSSIAN_BLUR_UNROLL 1
#include "Assets/Shaders/GaussianBlur.hlsl"
```

First pass:
```hlsl
return GaussianBlur(_SourceTex, sampler_SourceTex, float2(_SourceTex_TexelSize.x, 0), i.uv, 3, 3);
```

Second pass:
```hlsl
return GaussianBlur(_SourceTex, sampler_SourceTex, float2(0, _SourceTex_TexelSize.y), i.uv, 3, 3);
```

The produced code will be more efficient if `GAUSSIAN_BLUR_UNROLL` is set. However, it won't compile if the radius parameter is not a literal value.

Why
---
I could no longer be bothered writing kernel calculation code on CPU, and pass parameters to the shader for experimenting with sigma and radius, so I wrote this to let the Unity shader compiler generate the code I want.

Notes
---
- The function minimizes the texture fetches by bilinear filtering.
- UV calculations can be moved to vertex shader if further optimizations are required.
- Loop unroll will succeed even if the sigma parameter is dynamic. However, the generated code is not very efficient. It can be optimized by moving UV and weight calculations to the vertex shader.

Example Code Generated
---
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

