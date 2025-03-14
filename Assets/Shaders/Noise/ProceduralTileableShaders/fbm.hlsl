// Classic FBM implementation using Value noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param timeShift Time shift for each octave, range: [-inf, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, range: [0, inf]
float fbm(float2 pos, float2 scale, int octaves, float shift, float timeShift, float gain, float lacunarity, float octaveFactor, float seed) 
{
    float amplitude = gain;
    float time = timeShift;
    float2 frequency = scale;
    float2 offset = float2(shift, 0.0);
    float2 p = pos * frequency;
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(shift), cos(shift));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);

    float value = 0.0;
    for (int i = 0; i < octaves; i++) 
    {
        float n = noise(p / frequency, frequency, time, seed);
        value += amplitude * n;
        
        p = p * lacunarity + offset * float(1 + i);
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        time += timeShift;
        offset = mul(rotate, offset);
    }
    return value * 0.5 + 0.5;
}

// FBM implementation using Value noise with derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32], default: 2.0
// @param slopeness Slope intensity of the derivatives, range: [0, 1], default: 0.5
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, range: [0, inf], yz = derivative of the noise, range: [-1, 1]
float3 fbmd(float2 pos, float2 scale, int octaves, float2 shift, float timeShift, float gain, float2 lacunarity, float slopeness, float octaveFactor, float seed) 
{
    // fbm implementation based on Inigo Quilez
    float amplitude = gain;
    float time = timeShift;
    float2 frequency = scale;
    float2 p = pos * frequency;
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(shift.x), cos(shift.y));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);

    float3 value = comp3(0.0);
    float2 derivative = comp2(0.0);
    for (int i = 0; i < octaves; i++) 
    {
        float3 n =  noised(p / frequency, frequency, time, seed).xyz;
        derivative += n.yz;

        n *= amplitude;
        n.x /= (1.0 + mix(0.0, dot(derivative, derivative), slopeness));
        value += n; 
        
        p = (p + shift) * lacunarity;
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        shift = mul(rotate, shift);
        time += timeShift;
    }
    
    value.x = value.x * 0.5 + 0.5;
    return value;
}
float3 fbmd(float2 pos, float2 scale, int octaves, float shift, float timeShift, float gain, float lacunarity, float slopeness, float octaveFactor, float seed) 
{
    return fbmd(pos, scale, octaves, comp2(shift), timeShift, gain, comp2(lacunarity), slopeness, octaveFactor, seed);
}
float3 fbmd(float2 pos, float2 scale, int octaves, float2 shift, float timeShift, float gain, float lacunarity, float slopeness, float octaveFactor, float seed) 
{
    return fbmd(pos, scale, octaves, shift, timeShift, gain, comp2(lacunarity), slopeness, octaveFactor, seed);
}

// FBM implementation using Perlin noise with derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32], default: 2.0
// @param slopeness Slope intensity of the derivatives, range: [0, 1], default: 0.25
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param negative If true use a negative range for the noise values, will result in more contrast, range: [false, true]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, range: [-1, inf], yz = derivative of the noise, range: [-1, 1]
float3 fbmdPerlin(float2 pos, float2 scale, int octaves, float2 shift, float2x2 transform, float gain, float2 lacunarity, float slopeness, float octaveFactor, bool negative, float seed) 
{
    // fbm implementation based on Inigo Quilez
    float amplitude = gain;
    float2 frequency = floor(scale);
    float2 p = pos * frequency;
    octaveFactor = 1.0 + octaveFactor * 0.3;

    float3 value = comp3(0.0);
    float2 derivative = comp2(0.0);
    for (int i = 0; i < octaves; i++) 
    {
        float3 n = perlinNoised(p / frequency, frequency, transform, seed);
        derivative += n.yz;
        n.x = negative ? n.x : n.x * 0.5 + 0.5;
        n *= amplitude;
        value.x += n.x / (1.0 + mix(0.0, dot(derivative, derivative), slopeness));
        value.yz += n.yz; 
        
        p = (p + shift) * lacunarity;
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        transform *= transform;
    }

    return value;
}
float3 fbmdPerlin(float2 pos, float2 scale, int octaves, float2 shift, float axialShift, float gain, float2 lacunarity, float slopeness, float octaveFactor, bool negative, float seed) 
{
    float2 cosSin = float2(cos(axialShift), sin(axialShift));
    float2x2 transform = float2x2(cosSin.x, cosSin.y, -cosSin.y, cosSin.x) * float2x2(0.8, -0.6, 0.6, 0.8);
    return fbmdPerlin(pos, scale, octaves, shift, transform, gain, lacunarity, slopeness, octaveFactor, negative, seed);
}

// FBM implementation using Perlin noise, can also be used to create ridges based on the mode used.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param axialShift Axial or rotational shift for each octave, range: [-inf, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param mode Mode used in combining the noise for the ocatves, range: [0, 5]
// @param factor Pow intensity factor, range: [0, 10], default: 1.0
// @param offset Offsets the value of the noise, range: [-1, 1], default: 0.0
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, range: [0, inf]
float fbmPerlin(float2 pos, float2 scale, int octaves, float shift, float axialShift, float gain, float lacunarity, uint mode, float factor, float offset, float octaveFactor, float seed) 
{
    float amplitude = gain;
    float2 frequency = floor(scale);
    float angle = axialShift;
    float n = 1.0;
    float2 p = frac(pos) * frequency;

    float value = 0.0;
    for (int i = 0; i < octaves; i++) 
    {
        float pn = perlinNoise(p / frequency, frequency, angle, seed) + offset;
        if (mode == 0u)
        {
            n *= abs(pn);
        }
        else if (mode == 1u)
        {
            n = abs(pn);
        }
        else if (mode == 2u)
        {
            n = pn;
        }
        else if (mode == 3u)
        {
            n *= pn;
        }
        else if (mode == 4u)
        {
            n = pn * 0.5 + 0.5;
        }
        else
        {
            n *= pn * 0.5 + 0.5;
        }
        
        n = pow(n < 0.0 ? 0.0 : n, factor);
        value += amplitude * n;
        
        p = p * lacunarity + shift;
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        angle += axialShift;
    }
    return value;
}

// FBM implementation using Voronoi.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param timeShift Time shift for each octave, range: [-inf, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param interpolate Interpolate factor between the multiplication mode and normal mode, default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, range: [0, inf]
float4 fbmVoronoi(float2 pos, float2 scale, int octaves, float shift, float timeShift, float gain, float lacunarity, float octaveFactor, float jitter, float interpolate, float seed) 
{
    float amplitude = gain;
    float time = timeShift;
    float2 frequency = scale;
    float2 offset = float2(shift, 0.0);
    float2 p = pos * frequency;
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(shift), cos(shift));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);
    
    float n = 1.0;
    float4 value = comp4(0.0);
    for (int i = 0; i < octaves; i++) 
    {
        float3 v = voronoi(p / frequency, frequency, jitter, timeShift, seed);
        v.x = v.x * 2.0 - 1.0;
        n *= v.x;
        value += amplitude * float4(mix(v.x, n, interpolate), hash3D(v.yz));
        
        p = p * lacunarity + offset * float(1 + i);
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        time += timeShift;
        offset = mul(rotate, offset);
    }
    value.x = value.x * 0.5 + 0.5;
    return value;
}

// FBM implementation using a variation of Value noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf], default: 100.0
// @param timeShift Time shift for each octave, range: [-inf, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param translate Translate factors for the value noise , range: [-inf, inf], default: {0.5, -0.25, 0.15}
// @param warpStrength The warp factor used for domain warping, range: [-10, 10], default: 0.5
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, range: [0, inf]
float fbmGrid(float2 pos, float2 scale, int octaves, float shift, float timeShift, float gain, float lacunarity, float3 translate, float warpStrength, float octaveFactor, float seed) 
{
    float amplitude = gain;
    float time = timeShift;
    float2 frequency = scale;
    float2 offset = float2(shift, 0.0);
    float2 p = pos * frequency;
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(shift), cos(shift));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);

    float value = 0.0;
    for (int i = 0; i < octaves; i++) 
    {
        float2 pi = p / frequency + value * warpStrength;
        float4 mn;
        mn.xy = multiNoise(pi.xyxy + float2(0.0, translate.x).xxyy, frequency.xyxy, time, seed);
        mn.zw = multiNoise(pi.xyxy + translate.yyzz, frequency.xyxy, time, seed);
        mn.xy = mn.xy * mn.zw;

        float n = pow(abs(mn.x * mn.y), 0.25) * 2.0 - 1.0;
        value += amplitude * n;
        
        p = p * lacunarity + offset * float(1 + i);
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        time += timeShift;
        offset = mul(rotate, offset);
    }
    value = value * 0.5 + 0.5;
    return value * value;
}

float fbmGrid(float2 pos, float2 scale, int octaves, float shift, float timeShift, float gain, float lacunarity, float warpStrength, float octaveFactor, float seed) 
{
    float3 translate = (hash3D(comp2(seed)) * 2.0 - 1.0) * scale.xyx;
    return fbmGrid(pos, scale, octaves, shift, timeShift, gain, lacunarity, translate, warpStrength, octaveFactor, seed);
}

// FBM implementation using metaballs.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param timeShift Time shift for each octave, range: [-inf, inf]
// @param gain Gain for each fbm octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
// @param interpolate Interpolate factor between the multiplication mode and normal mode, default: 0.0
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param width Width and softness of the metaballs, range: [0, 1], default: {0.1, 0.01}
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, range: [0, inf]
float fbmMetaballs(float2 pos, float2 scale, int octaves, float shift, float timeShift, float gain, float lacunarity, float octaveFactor, float jitter, float interpolate, float2 width, float seed) 
{
    float amplitude = gain;
    float time = timeShift;
    float2 frequency = scale;
    float2 offset = float2(shift, 0.0);
    float2 p = pos * frequency;
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(shift), cos(shift));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);
    
    float n = 1.0;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) 
    {
        float cn = metaballs(p / frequency, frequency, jitter, timeShift, width.x, width.y, seed) * 2.0 - 1.0;
        n *= cn;
        value += amplitude * mix(n, abs(n), interpolate);
        
        p = p * lacunarity + offset * float(1 + i);
        frequency *= lacunarity;
        amplitude = pow(amplitude * gain, octaveFactor);
        time += timeShift;
        offset = mul(rotate, offset);
    }
    return value * 0.5 + 0.5;
}

// FBM implementation using value noise which returns multiple values.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param phase The phase for rotating the hash, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, range: [0, inf]
float4 fbmMulti(float2 pos, float2 scale, float lacunarity, int octaves, float phase, float seed) 
{    
    float4 seeds = float4(0.0, 1031.0, 537.0, 23.0) + seed;
    float f = 2.0 / lacunarity;
    
    float4 value = comp4(0.0);
    float w = 1.0;
    float acc = 0.0;
    for (int i = 0; i < octaves; i++) 
    {
        float2 ns = float2(scale / w);
        float4 n;
        n.xy = multiNoise(pos.xyxy, ns.xyxy, phase, seeds.xy);
        n.zw = multiNoise(pos.xyxy, ns.xyxy, phase, seeds.zw);
        value += (n * 0.5 + 0.5) * w;
        acc += w;
        w *= 0.5 * f;
    }
    return value / acc;
}
