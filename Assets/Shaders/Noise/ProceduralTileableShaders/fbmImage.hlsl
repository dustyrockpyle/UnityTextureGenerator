float luma(const in float4 color) { return dot(float3(0.2558, 0.6511, 0.0931), color.rgb); }		
float2 sobel(sampler2D tex, float4 textureSize, float2 uv, float spread)
{
    float3 offset = float3(textureSize.xy, 0.0) * spread;
    float2 grad = comp2(0.0);
    grad.x -= luma(tex2D(tex, uv - offset.xy)) * 1.0;
    grad.x -= luma(tex2D(tex, uv - offset.xz)) * 2.0;
    grad.x -= luma(tex2D(tex, uv + offset.xy * float2(-1.0, 1.0))) * 1.0;
    grad.x += luma(tex2D(tex, uv + offset.xy * float2(1.0, -1.0))) * 1.0;
    grad.x += luma(tex2D(tex, uv + offset.xz)) * 2.0;
    grad.x += luma(tex2D(tex, uv + offset.xy)) * 1.0;
    grad.y -= luma(tex2D(tex, uv - offset.xy)) * 1.0;
    grad.y -= luma(tex2D(tex, uv - offset.zy)) * 2.0;
    grad.y -= luma(tex2D(tex, uv + offset.xy * float2(1.0, -1.0))) * 1.0;
    grad.y += luma(tex2D(tex, uv + offset.xy * float2(-1.0, 1.0))) * 1.0;
    grad.y += luma(tex2D(tex, uv + offset.zy)) * 2.0;
    grad.y += luma(tex2D(tex, uv + offset.xy)) * 1.0;
    return grad;
}	
float2 grayscaleSobel(sampler2D tex, float4 textureSize, float2 uv, float spread)
{
    float3 offset = float3(textureSize.xy, 0.0) * spread;
    float2 grad = comp2(0.0);
    grad.x -= tex2D(tex, uv - offset.xy).r * 1.0;
    grad.x -= tex2D(tex, uv - offset.xz).r * 2.0;
    grad.x -= tex2D(tex, uv + offset.xy * float2(-1.0, 1.0)).r * 1.0;
    grad.x += tex2D(tex, uv + offset.xy * float2(1.0, -1.0)).r * 1.0;
    grad.x += tex2D(tex, uv + offset.xz).r * 2.0;
    grad.x += tex2D(tex, uv + offset.xy).r * 1.0;
    grad.y -= tex2D(tex, uv - offset.xy).r * 1.0;
    grad.y -= tex2D(tex, uv - offset.zy).r * 2.0;
    grad.y -= tex2D(tex, uv + offset.xy * float2(1.0, -1.0)).r * 1.0;
    grad.y += tex2D(tex, uv + offset.xy * float2(-1.0, 1.0)).r * 1.0;
    grad.y += tex2D(tex, uv + offset.zy).r * 2.0;
    grad.y += tex2D(tex, uv + offset.xy).r * 1.0;
    return grad;
}

// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param axialShift Axial or rotational shift for each octave, range: [0, inf]
// @param gain Gain for each octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param slopeness Slope intensity of the derivatives, range: [0, 1], default: 0.5
// @param spread Spread for the derivatives, range: [1, 16], default: 1.0
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
float3 fbmImage(sampler2D tex, float4 textureSize, float2 uv, float2 scale, uint octaves, float shift, float axialShift, float gain, float lacunarity, float slopeness, float spread, float octaveFactor)
{
    // based on derivative fbm by Inigo Quilez
    float3 value = comp3(0.0);
    float2 derivative = comp2(0.0);
    
    float amplitude = gain;
    float2 frequency = floor(scale);
    float2 offset = float2(shift, 0.0);
    float angle = 0.0;
    axialShift = 3.1415926 * 0.5 * floor(float(octaves) * axialShift);
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(axialShift), cos(axialShift));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);

    float2 p = uv * frequency;
    for (uint i = 0u; i < octaves; i++)
    {
        float3 color = tex2D(tex, p).rgb;
        float2 grad = sobel(tex, textureSize, p, spread);
        derivative += grad;
        value += amplitude * color / (1.0 + mix(0.0, dot(derivative, derivative), slopeness));

        amplitude = pow(amplitude * gain, octaveFactor);
        p = mul(rotate, p * lacunarity + offset);
        frequency *= lacunarity;
        angle += axialShift;
        offset = mul(rotate, offset);
    }
    return value;
}

// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param octaves Number of octaves for the fbm, range: [1, inf]
// @param shift Position shift for each octave, range: [0, inf]
// @param axialShift Axial or rotational shift for each octave, range: [0, inf]
// @param gain Gain for each octave, range: [0, 2], default: 0.5
// @param lacunarity Frequency of the fbm, must be integer for tileable results, range: [1, 32]
// @param slopeness Slope intensity of the derivatives, range: [0, 1], default: 0.5
// @param spread Spread for the derivatives, range: [1, 16], default: 1.0
// @param octaveFactor The octave intensity factor, the lower the more pronounced the lower octaves will be, range: [-1, 1], default: 0.0
float3 fbmGrayscaleImaged(sampler2D tex, float4 textureSize, float2 uv, float2 scale, uint octaves, float shift, float axialShift, float gain, float lacunarity, float slopeness, float spread, float octaveFactor)
{
    float value = 0.0;
    float2 derivative = comp2(0.0);
    
    float amplitude = gain;
    float2 frequency = floor(scale);
    float2 offset = float2(shift, 0.0);
    float angle = 0.0;
    axialShift = 3.1415926 * 0.5 * floor(float(octaves) * axialShift);
    octaveFactor = 1.0 + octaveFactor * 0.12;
    
    float2 sinCos = float2(sin(axialShift), cos(axialShift));
    float2x2 rotate = float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y);

    float2 p = uv * frequency;
    for (uint i = 0u; i < octaves; i++)
    {
        float lum = tex2D(tex, p).r;
        float2 grad = grayscaleSobel(tex, textureSize, p, spread);
        derivative += grad;
        value += amplitude * lum / (1.0 + mix(0.0, dot(derivative, derivative), slopeness));
        
        amplitude = pow(amplitude * gain, octaveFactor);
        p = mul(rotate, p * lacunarity + offset);
        frequency *= lacunarity;
        angle += axialShift;
        offset = mul(rotate, offset);
    }
    return float3(value, derivative);
}
