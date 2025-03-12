
// 1D Value noise.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf]
// @return Value of the noise, range: [-1, 1]
float noise(float pos, float scale, float seed)
{
    pos *= scale;
    float2 i = floor(pos) + float2(0.0, 1.0);
    float f = pos - i.x;
    i = mod(i, comp2(scale)) + seed;

    float u = noiseInterpolate(f);
    return mix(hash1D(i.x), hash1D(i.y), u) * 2.0 - 1.0;
}

// 2D Value noise.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf]
// @return Value of the noise, range: [-1, 1]
float noise(float2 pos, float2 scale, float seed) 
{
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float2 f = pos - i.xy;
    i = mod(i, scale.xyxy) + seed;

    float4 hash = multiHash2D(i);
    float a = hash.x;
    float b = hash.y;
    float c = hash.z;
    float d = hash.w;

    float2 u = noiseInterpolate(f);
    float value = mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
    return value * 2.0 - 1.0;
}

// 2D Value noise.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param phase The phase for rotating the hash, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf]
// @return Value of the noise, range: [-1, 1]
float noise(float2 pos, float2 scale, float phase, float seed) 
{
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float2 f = pos - i.xy;
    i = mod(i, scale.xyxy) + seed;

    float4 hash = multiHash2D(i);
    hash = 0.5 * sin(phase + kPI2 * hash) + 0.5;
    float a = hash.x;
    float b = hash.y;
    float c = hash.z;
    float d = hash.w;

    float2 u = noiseInterpolate(f);
    float value = mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
    return value * 2.0 - 1.0;
}

// 2D Value noise with derivatives.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf]
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 noised(float2 pos, float2 scale, float seed) 
{
    // value noise with derivatives based on Inigo Quilez
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float2 f = pos - i.xy;
    i = mod(i, scale.xyxy) + seed;

    float4 hash = multiHash2D(i);
    float a = hash.x;
    float b = hash.y;
    float c = hash.z;
    float d = hash.w;
    
    float4 udu = noiseInterpolateDu(f);    
    float abcd = a - b - c + d;
    float value = a + (b - a) * udu.x + (c - a) * udu.y + abcd * udu.x * udu.y;
    float2 derivative = udu.zw * (udu.yx * abcd + float2(b, c) - a);
    return float3(value * 2.0 - 1.0, derivative);
}

// 2D Value noise with derivatives.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param phase The phase for rotating the hash, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf]
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 noised(float2 pos, float2 scale, float phase, float seed) 
{
    const float kPI2 = 6.2831853071;
    // value noise with derivatives based on Inigo Quilez
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float2 f = pos - i.xy;
    i = mod(i, scale.xyxy) + seed;

    float4 hash = multiHash2D(i);
    hash = 0.5 * sin(phase + kPI2 * hash) + 0.5;
    float a = hash.x;
    float b = hash.y;
    float c = hash.z;
    float d = hash.w;
    
    float4 udu = noiseInterpolateDu(f);    
    float abcd = a - b - c + d;
    float value = a + (b - a) * udu.x + (c - a) * udu.y + abcd * udu.x * udu.y;
    float2 derivative = udu.zw * (udu.yx * abcd + float2(b, c) - a);
    return float3(value * 2.0 - 1.0, derivative);
}

// 3D Value noise with height that is tileable on the XY axis.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param time The height phase for the noise value, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [-1, 1]
float noise3d(float2 pos, float2 scale, float height, float seed)
{
    // classic value noise with 3D
    pos *= scale;
    float3 i = floor(float3(pos.xy, height));
    float3 ip1 = i + comp3(1.0);
    float3 f = float3(pos.xy, height) - i;
    
    float4 mi = mod(float4(i.xy, ip1.xy), scale.xyxy);
    i.xy = mi.xy;
    ip1.xy = mi.zw;

    float4 hashLow, hashHigh;
    multiHash3D(i + seed, ip1 + seed, hashLow, hashHigh);
    
    float3 u = noiseInterpolate(f);
    float4 r = mix(hashLow, hashHigh, u.z);
    r = mix(r.xyxz, r.zwyw, u.yyxx);
    return (r.x + (r.y - r.x) * u.x) * 2.0 - 1.0;
}

// 3D Value noise with height and derivatives that is tileable on the XY axis.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param time The height phase for the noise value, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf]
// @return x = value of the noise, yz = derivative of the noise, w = derivative of the time, range: [-1, 1]
float4 noised3d(float2 pos, float2 scale, float time, float seed) 
{
    // based on Analytical Noise Derivatives by Brian Sharpe
    // classic value noise with 3D
    pos *= scale;
    float3 i = floor(float3(pos, time));
    float3 ip1 = i + comp3(1.0);
    float3 f = float3(pos, time) - i;
    
    float4 mi = mod(float4(i.xy, ip1.xy), scale.xyxy);
    i.xy = mi.xy;
    ip1.xy = mi.zw;

    float4 hashLow, hashHigh;
    multiHash3D(i + seed, ip1 + seed, hashLow, hashHigh);

    float3 u, du;
    noiseInterpolateDu(f, u, du);
    float4 res0 = mix(hashLow, hashHigh, u.z);
    float4 res1 = mix(res0.xyxz, res0.zwyw, u.yyxx);
    float4 res2 = mix(float4(hashLow.xy, hashHigh.xy), float4(hashLow.zw, hashHigh.zw), u.y);
    float2 res3 = mix(res2.xz, res2.yw, u.x);
    float4 results = float4(res1.x, 0.0, 0.0, 0.0) + (float4(res1.yyw, res3.y) - float4(res1.xxz, res3.x)) * float4(u.x, du);
    return float4(results.x * 2.0 - 1.0, results.yzw);
}

// 2D Value noise that returns two values.
// @param scale Number of tiles, must be an integer for tileable results, range: [2, inf]
// @param phase The phase for rotating the hash, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf]
// @return Value of the noise, range: [-1, 1]
float2 multiNoise(float4 pos, float4 scale, float phase, float2 seed) 
{
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float4 i = floor(pos);
    float4 f = pos - i;
    float4 i0 = mod(i.xyxy + float2(0.0, 1.0).xxyy, scale.xyxy) + seed.x;
    float4 i1 = mod(i.zwzw + float2(0.0, 1.0).xxyy, scale.xyxy) + seed.y;

    float4 hash0 = multiHash2D(i0);
    hash0 = 0.5 * sin(phase + kPI2 * hash0) + 0.5;
    float4 hash1 = multiHash2D(i1);
    hash1 = 0.5 * sin(phase + kPI2 * hash1) + 0.5;
    float2 a = float2(hash0.x, hash1.x);
    float2 b = float2(hash0.y, hash1.y);
    float2 c = float2(hash0.z, hash1.z);
    float2 d = float2(hash0.w, hash1.w);

    float4 u = noiseInterpolate(f);
    float2 value = mix(a, b, u.xz) + (c - a) * u.yw * (1.0 - u.xz) + (d - b) * u.xz * u.yw;
    return value * 2.0 - 1.0;
}

// 2D Variant of Value noise that produces ridge-like noise by using multiple noise values.
// @param scale Number of tiles, must be integer for tileable results, range: [2, inf]
// @param translate Translate factors for the value noise , range: [-inf, inf], default: {0.5, -0.25, 0.15}
// @param intensity The contrast for the noise, range: [0, 1], default: 0.75
// @param time The height phase for the noise value, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf]
// @return Value of the noise, range: [0, 1]
float gridNoise(float2 pos, float2 scale, float3 translate, float intensity, float time, float seed)
{
    float4 n; 
    n.xy = multiNoise(pos.xyxy + float2(0.0, translate.x).xxyy, scale.xyxy, time, seed);
    n.zw = multiNoise(pos.xyxy + translate.yyzz, scale.xyxy, time, seed);
    n.xy = n.xy * n.zw;
    
    float t = abs(n.x * n.y);
    return pow(t, mix(0.5, 0.1, intensity));
}

// 2D Variant of Value noise that produces ridge-like noise by using multiple noise values.
// @param scale Number of tiles, must be integer for tileable results, range: [2, inf]
// @param intensity The contrast for the noise, range: [0, 1], default: 0.75
// @param time The height phase for the noise value, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf]
// @return Value of the noise, range: [0, 1]
float gridNoise(float2 pos, float2 scale, float intensity, float time, float seed)
{
    float4 translate = float4(0.0, (hash3D(comp2(seed)) * 2.0 - 1.0) * scale.xyx);
    
    float4 n; 
    n.xy = multiNoise(pos.xyxy + translate.xxyy, scale.xyxy, time, seed);
    n.zw = multiNoise(pos.xyxy + translate.zzww, scale.xyxy, time, seed);
    n.xy = n.xy * n.zw;
    
    float t = abs(n.x * n.y);
    return pow(t, mix(0.5, 0.1, intensity));
}

// 2D Variant of Value noise that produces dots with random size or luminance.
// @param scale Number of tiles, must be integer for tileable results, range: [2, inf]
// @param density The density of the dots distribution, range: [0, 1], default: 1.0
// @param size The radius of the dots, range: [0, 1], default: 0.5
// @param sizeVariation The variation for the size of the dots, range: [0, 1], default: 0.75
// @param roundness The roundness of the dots, if zero will result in square, range: [0, 1], default: 1.0
// @param seed Seed to randomize result, range: [0, inf]
// @return x = value of the noise, y = random luminance value, z = size of the dot, range: [0, 1]
float3 dotsNoise(float2 pos, float2 scale, float density, float size, float sizeVariation, float roundness, float seed) 
{
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float2 f = pos - i.xy;
    i = mod(i, scale.xyxy);
    
    float4 hash = hash4D(i.xy + seed);
    if (hash.w > density)
        return comp3(0.0);

    float radius = clamp(size + (hash.z * 2.0 - 1.0) * sizeVariation * 0.5, 0.0, 1.0);
    float value = radius / size;  
    radius = 2.0 / radius;
    f = f * radius - (radius - 1.0);
    f += hash.xy * (radius - 2.0);
    f = pow(abs(f), comp2((mix(20.0, 1.0, sqrt(roundness)))));

    float u = 1.0 - min(dot(f, f), 1.0);
    return float3(clamp(u * u * u * value, 0.0, 1.0), hash.w, hash.z);
}

// 2D Variant of Value noise that produces lines of random color and configurable width.
// @param scale Number of tiles, must be integer for tileable results, range: [2, inf]
// @param count The density of the lines, range: [1, inf], default: 4.0
// @param jitter Jitter factor for the lines, if zero then it will result straight lines, range: [0, 1], default: 1.0
// @param smoothness The radius of the dots, range: [0, 1], default: 0.5
// @param seed Seed to randomize result, range: [0, inf]
// @return x = value of the noise, range: [0, 1], y = id of lines, range: [0, count] 
float2 randomLines(float2 pos, float2 scale, float count, float width, float jitter, float2 smoothness, float phase, float seed)
{
    float strength = jitter * 1.25;

    // compute gradient
    // TODO: compute the gradient analytically
    float2 grad;
    float3 offsets = float3(1.0, 0.0, -1.0) / 1024.0;
    float4 p = pos.xyxy + offsets.xyzy;
    float2 nv = count * (strength * multiNoise(p, scale.xyxy, phase, comp2(seed)) + p.yw);
    grad.x = nv.x - nv.y;
    p = pos.xyxy + offsets.yxyz;
    nv = count * (strength * multiNoise(p, scale.xyxy, phase, comp2(seed)) + p.yw);
    grad.y = nv.x - nv.y;
    
    float v =  count * (strength * noise(pos, scale, phase, seed) + pos.y);
    float w = frac(v) / length(grad / (2.0 * offsets.x));
    width *= 0.1;
    smoothness *= width;
    smoothness += max(abs(grad.x), abs(grad.y)) * 0.02;
    
    float d = smoothstep(0.0, smoothness.x, w) - smoothstep(max(width - smoothness.y, 0.0), width, w);
    return float2(d, mod(floor(v), count));
}

// 2D Variant of Value noise that produces lines of random color and configurable width.
// @param scale Number of tiles, must be integer for tileable results, range: [2, inf]
// @param count The density of the lines, range: [1, inf], default: 4.0
// @param jitter Jitter factor for the lines, if zero then it will result straight lines, range: [0, 1], default: 1.0
// @param smoothness The radius of the dots, range: [0, 1], default: 0.5
// @param colorVariation The variation for the color of the lines, range: [0, 1], default: 1.0
// @param seed Seed to randomize result, range: [0, inf]
// @return Color of the lines, black if background, range: [0, 1]
float4 randomLines(float2 pos, float2 scale, float count, float width, float jitter, float2 smoothness, float phase, float colorVariation, float seed)
{
    float2 l = randomLines(pos, scale, count, width, jitter, smoothness, phase, seed);
    float3 r = hash3D(l.yy + seed);
    return float4(l.x * (r.x <= colorVariation ? r : r.xxx), l.x);
}
