// 2D Perlin noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [-1, 1]
float perlinNoise(float2 pos, float2 scale, float seed)
{
    // based on Modifications to Classic Perlin Noise by Brian Sharpe: https://archive.is/cJtlS
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;

    // grid gradients
    float4 gradientX, gradientY;
    multiHash2D(i, gradientX, gradientY);
    gradientX -= 0.49999;
    gradientY -= 0.49999;

    // perlin surflet
    float4 gradients = rsqrt(gradientX * gradientX + gradientY * gradientY) * (gradientX * f.xzxz + gradientY * f.yyww);
    // normalize: 1.0 / 0.75^3
    gradients *= 2.3703703703703703703703703703704;
    float4 lengthSq = f * f;
    lengthSq = lengthSq.xzxz + lengthSq.yyww;
    float4 xSq = 1.0 - min(comp4(1.0), lengthSq); 
    xSq = xSq * xSq * xSq;
    return dot(xSq, gradients);
}

// 2D Perlin noise with gradients transform (i.e. can be used to rotate the gradients).
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param transform transform matrix for the noise gradients.
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [-1, 1]
float perlinNoise(float2 pos, float2 scale, float2x2 transform, float seed)
{
    // based on Modifications to Classic Perlin Noise by Brian Sharpe: https://archive.is/cJtlS
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;

    // grid gradients
    float4 gradientX, gradientY;
    multiHash2D(i, gradientX, gradientY);
    gradientX -= 0.49999;
    gradientY -= 0.49999;

    // transform gradients
    float4 mt = float4(transform);
    float4 rg = float4(gradientX.x, gradientY.x, gradientX.y, gradientY.y);
    rg = rg.xxzz * mt.xyxy + rg.yyww * mt.zwzw;
    gradientX.xy = rg.xz;
    gradientY.xy = rg.yw;

    rg = float4(gradientX.z, gradientY.z, gradientX.w, gradientY.w);
    rg = rg.xxzz * mt.xyxy + rg.yyww * mt.zwzw;
    gradientX.zw = rg.xz;
    gradientY.zw = rg.yw;

    // perlin surflet
    float4 gradients = rsqrt(gradientX * gradientX + gradientY * gradientY) * (gradientX * f.xzxz + gradientY * f.yyww);
    // normalize: 1.0 / 0.75^3
    gradients *= 2.3703703703703703703703703703704;
    f = f * f;
    f = f.xzxz + f.yyww;
    float4 xSq = 1.0 - min(comp4(1.0), f); 
    return dot(xSq * xSq * xSq, gradients);
}

// 2D Perlin noise with gradients rotation.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param rotation Rotation for the noise gradients, useful to animate flow, range: [0, PI]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [-1, 1]
float perlinNoise(float2 pos, float2 scale, float rotation, float seed) 
{
    float2 sinCos = float2(sin(rotation), cos(rotation));
    return perlinNoise(pos, scale, float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y), seed);
}

// 2D Perlin noise with derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 perlinNoised(float2 pos, float2 scale, float seed)
{
    // based on Modifications to Classic Perlin Noise by Brian Sharpe: https://archive.is/cJtlS
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;

    // grid gradients
    float4 gradientX, gradientY;
    multiHash2D(i, gradientX, gradientY);
    gradientX -= 0.49999;
    gradientY -= 0.49999;

    // perlin surflet
    float4 gradients = rsqrt(gradientX * gradientX + gradientY * gradientY) * (gradientX * f.xzxz + gradientY * f.yyww);
    float4 m = f * f;
    m = m.xzxz + m.yyww;
    m = max(1.0 - m, 0.0);
    float4 m2 = m * m;
    float4 m3 = m * m2;
    // compute the derivatives
    float4 m2Gradients = -6.0 * m2 * gradients;
    float2 grad = float2(dot(m2Gradients, f.xzxz), dot(m2Gradients, f.yyww)) + float2(dot(m3, gradientX), dot(m3, gradientY));
    // sum the surflets and normalize: 1.0 / 0.75^3
    return float3(dot(m3, gradients), grad) * 2.3703703703703703703703703703704;
}

// 2D Perlin noise with derivatives and gradients transform (i.e. can be used to rotate the gradients).
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param rotation Rotation for the noise gradients, useful to animate flow, range: [0, PI]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 perlinNoised(float2 pos, float2 scale, float2x2 transform, float seed)
{
    // based on Modifications to Classic Perlin Noise by Brian Sharpe: https://archive.is/cJtlS
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;

    // grid gradients
    float4 gradientX, gradientY;
    multiHash2D(i, gradientX, gradientY);
    gradientX -= 0.49999;
    gradientY -= 0.49999;

    // transform gradients
    float4 mt = float4(transform);
    float4 rg = float4(gradientX.x, gradientY.x, gradientX.y, gradientY.y);
    rg = rg.xxzz * mt.xyxy + rg.yyww * mt.zwzw;
    gradientX.xy = rg.xz;
    gradientY.xy = rg.yw;

    rg = float4(gradientX.z, gradientY.z, gradientX.w, gradientY.w);
    rg = rg.xxzz * mt.xyxy + rg.yyww * mt.zwzw;
    gradientX.zw = rg.xz;
    gradientY.zw = rg.yw;

    // perlin surflet
    float4 gradients = rsqrt(gradientX * gradientX + gradientY * gradientY) * (gradientX * f.xzxz + gradientY * f.yyww);
    float4 m = f * f;
    m = m.xzxz + m.yyww;
    m = max(1.0 - m, 0.0);
    float4 m2 = m * m;
    float4 m3 = m * m2;
    // compute the derivatives
    float4 m2Gradients = -6.0 * m2 * gradients;
    float2 grad = float2(dot(m2Gradients, f.xzxz), dot(m2Gradients, f.yyww)) + float2(dot(m3, gradientX), dot(m3, gradientY));
    // sum the surflets and normalize: 1.0 / 0.75^3
    return float3(dot(m3, gradients), grad) * 2.3703703703703703703703703703704;
}

// 2D Perlin noise with derivatives and gradients rotation.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param rotation Rotation for the noise gradients, useful to animate flow, range: [0, PI]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 perlinNoised(float2 pos, float2 scale, float rotation, float seed) 
{
    float2 sinCos = float2(sin(rotation), cos(rotation));
    return perlinNoised(pos, scale, float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y), seed);
}

// 2D Variant of Perlin noise that produces and organic-like noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param density The density of the lower frequency details, range: [0, 1], default: 1.0
// @param phase The phase of the noise, range: [-inf, inf], default: {0, 0}
// @param contrast Controls the contrast of the result, range: [0, 1], default: 0.0
// @param highlights Controls the highlights of the , range: [0, 1], default: 0.25
// @param shift Shifts the angle of the highlights, range: [0, 1], default: 0.5
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [0, 1]
float organicNoise(float2 pos, float2 scale, float density, float2 phase, float contrast, float highlights, float shift, float seed)
{
    float2 s = mix(comp2(1.0), scale - 1.0, density);
    float nx = perlinNoise(pos + phase, scale, seed);
    float ny = perlinNoise(pos, s, seed);

    float n = length(float2(nx, ny) * mix(float2(2.0, 0.0), float2(0.0, 2.0), shift));
    n = pow(n, 1.0 + 8.0 * contrast) + (0.15 * highlights) / n;
    return n * 0.5;
}
