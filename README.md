Separable Gaussian Blur for URP
===

Separable Gaussian blur function with configurable sigma and radius.

The delta parameter should be (texelSize.x, 0), and (0, texelSize.y) for each passes.

This function is used to quickly play around with sigma and radius values to find the optimal parameters in development.

Replacing the sigma and radius parameters with literal values lets the Unity shader compiler produce efficient code.

Do NOT use this function if parameters must be configurable for the shipping product.

Usage
---

First pass:
```hlsl
return GaussianBlur(_SourceTex, sampler_SourceTex, float2(_SourceTex_TexelSize.x, 0), i.uv, 3, 3);
```

Second pass:
```hlsl
return GaussianBlur(_SourceTex, sampler_SourceTex, float2(0, _SourceTex_TexelSize.y), i.uv, 3, 3);
```

Why
---
I could no longer be bothered writing kernel calculation code on CPU, and pass parameters to the shader for experimenting with sigma and radius, so I wrote this to  let the Unity shader compiler generate the code I want.

Notes
---
- The function minimizes the texture fetches by bilinear filtering.

Example Code Generated
---
- Sigma = 3
- Radius = 3

```glsl
u_xlat0.xz = _SourceTex_TexelSize.xx;
u_xlat0.y = float(-2.4309988);
u_xlat0.w = float(-0.654208839);
u_xlat0 = u_xlat0 * vec4(-2.4309988, 0.0, -0.654208839, 0.0) + vs_TEXCOORD0.xyxy;
u_xlat16_1 = texture(_SourceTex_xlat0.zw);
u_xlat16_0 = texture(_SourceTex_xlat0.xy);
u_xlat16_1 = u_xlat16_1 * vec4(0.253390133, 0.253390133, 0.253390133, 0.253390133);
u_xlat16_0 = u_xlat16_0 * vec4(0.246609837, 0.246609837, 0.246609837, 0.246609837) + u_xlat16_1;
u_xlat1.xz = _SourceTex_TexelSize.xx;
u_xlat1.y = float(0.654208839);
u_xlat1.w = float(2.4309988);
u_xlat1 = u_xlat1 * vec4(0.654208839, 0.0, 2.4309988, 0.0) + vs_TEXCOORD0.xyxy;
u_xlat16_2 = texture(_SourceTex_xlat1.xy);
u_xlat16_1 = texture(_SourceTex_xlat1.zw);
u_xlat16_0 = u_xlat16_2 * vec4(0.253390133, 0.253390133, 0.253390133, 0.253390133) + u_xlat16_0;
u_xlat16_0 = u_xlat16_1 * vec4(0.246609837, 0.246609837, 0.246609837, 0.246609837) + u_xlat16_0;
u_xlat16_0 = u_xlat16_0 * vec4(0.25, 0.25, 0.25, 0.25);
SV_Target0 = u_xlat16_0;
```
