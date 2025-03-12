
// Domain warping using a factal sum of value noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param factors Controls the warp Q and R factors, range: [-1, 1], default: float2(1.0, 1.0)
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shifts Shift or seed values for the Q and R domain warp factors, range: [0, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param slopeness Slope intensity of the derivatives, range: [0, 1], default: 0.5
// @param phase Phase to rotated the noise gradients, range: [0, PI]
// @param negative If true use a negative range for the noise values, range: [false, true]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
float fbmWarp(float2 pos, float2 scale, float2 factors, int octaves, float4 shifts, float timeShift, float gain, float2 lacunarity, float slopeness, float octaveFactor, bool negative, float seed,
              out float2 q, out float2 r) 
{
    float qfactor = factors.x;
    float rfactor = factors.y;
    q.x = fbmd(pos, scale, octaves, comp2(0.0), timeShift, gain, lacunarity, slopeness, octaveFactor, seed).x;
    q.y = fbmd(pos, scale, octaves, comp2(shifts.x), timeShift, gain, lacunarity, slopeness, octaveFactor, seed).x;
    q = negative ? q * 2.0 - 1.0 : q;
    
    float2 np = pos + qfactor * q;
    r.x = fbmd(np, scale, octaves, comp2(shifts.y), timeShift, gain, lacunarity, slopeness, octaveFactor, seed).x;
    r.y = fbmd(np, scale, octaves, comp2(shifts.z), timeShift, gain, lacunarity, slopeness, octaveFactor, seed).x;
    r = negative ? r * 2.0 - 1.0 : r;

    return fbmd(pos + r * rfactor, scale, octaves, comp2(shifts.w), timeShift, gain, lacunarity, slopeness, octaveFactor, seed).x;
}

// Domain warping using a factal sum of perlin noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param factors Controls the warp Q and R factors, range: [-1, 1], default: float2(0.2, 0.2)
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shifts Shift or seed values for the Q and R domain warp factors, range: [0, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param slopeness Slope intensity of the derivatives, range: [0, 1], default: 0.5
// @param phase Phase to rotated the noise gradients, range: [0, PI]
// @param negative If true use a negative range for the noise values, range: [false, true]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
float fbmPerlinWarp(float2 pos, float2 scale, float2 factors, int octaves, float4 shifts, float timeShift, float gain, float2 lacunarity, float slopeness, float octaveFactor, bool negative, float seed,
                      out float2 q, out float2 r) 
{
    float qfactor = factors.x;
    float rfactor = factors.y;
    q.x = fbmdPerlin(pos, scale, octaves, comp2(0.0), timeShift, gain, lacunarity, slopeness, octaveFactor, negative, seed).x;
    q.y = fbmdPerlin(pos, scale, octaves, comp2(shifts.x), timeShift, gain, lacunarity, slopeness, octaveFactor, negative, seed).x;
    
    float2 np = pos + qfactor * q;
    r.x = fbmdPerlin(np, scale, octaves, comp2(shifts.y), timeShift, gain, lacunarity, slopeness, octaveFactor, negative, seed).x;
    r.y = fbmdPerlin(np, scale, octaves, comp2(shifts.z), timeShift, gain, lacunarity, slopeness, octaveFactor, negative, seed).x;
    
    return fbmdPerlin(pos + r * rfactor, scale, octaves, comp2(shifts.w), timeShift, gain, lacunarity, slopeness, octaveFactor, negative, seed).x;
}

// Domain warping using the derivatives of gradient noise.
// @param factors Controls the warp Q and R factors, range: [-1, 1], default: float2(1.0, 1.0)
// @param seeds Seeds for the Q and R domain warp factors, range: [-inf, inf]
// @param curl Curl or bend of the noise, range: [0, 1], default: 0.5
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
float curlWarp(float2 pos, float2 scale, float2 factors, float4 seeds, float curl, float seed,
               out float2 q, out float2 r)
{
    float qfactor = factors.x;
    float rfactor = factors.y;
    float2 curlFactor = float2(1.0, -1.0) * float2(curl, 1.0 - curl);
    
    float2 n = gradientNoised(pos, scale, seed).zy * curlFactor;
    q.x = n.x + n.y;
    n = gradientNoised(pos + hash2D(seeds.x), scale, seed).zy * curlFactor;
    q.y = n.x + n.y;
    
    float2 np = pos + qfactor * q;
    n = gradientNoised(np + hash2D(seeds.y), scale, seed).zy * curlFactor;
    r.x = n.x + n.y;
    n = gradientNoised(np + hash2D(seeds.z), scale, seed).zy * curlFactor;
    r.y = n.x + n.y;

    return perlinNoise(pos + r * rfactor + hash2D(seeds.w), scale, seed);
}

// Domain warping using the derivatives of perlin noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param strength Controls the warp strength, range: [-1, 1]
// @param phase Noise phase, range: [-inf, inf]
// @param spread The gradient spread, range: [0.001, inf], default: 0.001
// @param factor Pow intensity factor, range: [0, 10]
float perlinNoiseWarp(float2 pos, float2 scale, float strength, float phase, float factor, float spread, float seed)
{
    float2 offset = float2(spread, 0.0);
    strength *= 32.0 / max(scale.x, scale.y);
    
    float4 gp;
    gp.x = perlinNoise(pos - offset.xy, scale, phase, seed);
    gp.y = perlinNoise(pos + offset.xy, scale, phase, seed);
    gp.z = perlinNoise(pos - offset.yx, scale, phase, seed);
    gp.w = perlinNoise(pos + offset.yx, scale, phase, seed);
    gp = pow(gp, comp4(factor));
    float2 warp = float2(gp.y - gp.x, gp.w - gp.z);
    return pow(perlinNoise(pos + warp * strength, scale, phase, seed), factor);
}
