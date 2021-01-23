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
```
return GaussianBlur(_SourceTex, sampler_SourceTex, float2(_SourceTex_TexelSize.x, 0), i.uv, 3, 5);
```

Second pass:
```
return GaussianBlur(_SourceTex, sampler_SourceTex, float2(0, _SourceTex_TexelSize.y), i.uv, 3, 5);
```

Why
---
I could no longer be bothered writing kernel calculation code on CPU, and pass parameters to the shader for experimenting with sigma and radius, so I wrote this to  let the Unity shader compiler generate the code I want.

Notes
---
- The function minimizes the texture fetches by bilinear filtering.
