// 2D Gradient noise.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [-1, 1]
float gradientNoise(float2 pos, float2 scale, float seed) 
{
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;

    float4 hashX, hashY;
    smultiHash2D(i, hashX, hashY);

    float4 gradients = hashX * f.xzxz + hashY * f.yyww;
    float2 u = noiseInterpolate(f.xy);
    float2 g = mix(gradients.xz, gradients.yw, u.x);
    return 1.4142135623730950 * mix(g.x, g.y, u.y);
}

// 2D Gradient noise with gradients transform (i.e. can be used to rotate the gradients).
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param transform Transform matrix for the noise gradients.
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Value of the noise, range: [-1, 1]
float gradientNoise(float2 pos, float2 scale, float2x2 transform, float seed) 
{
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;
    
    float4 hashX, hashY;
    smultiHash2D(i, hashX, hashY);

    // transform gradients
    float4 m = float4(transform);
    float4 rh = float4(hashX.x, hashY.x, hashX.y, hashY.y);
    rh = rh.xxzz * m.xyxy + rh.yyww * m.zwzw;
    hashX.xy = rh.xz;
    hashY.xy = rh.yw;

    rh = float4(hashX.z, hashY.z, hashX.w, hashY.w);
    rh = rh.xxzz * m.xyxy + rh.yyww * m.zwzw;
    hashX.zw = rh.xz;
    hashY.zw = rh.yw;
    
    float4 gradients = hashX * f.xzxz + hashY * f.yyww;
    float2 u = noiseInterpolate(f.xy);
    float2 g = mix(gradients.xz, gradients.yw, u.x);
    return 1.4142135623730950 * mix(g.x, g.y, u.y);
}

float gradientNoise(float2 pos, float2 scale, float rotation, float seed) 
{
    float2 sinCos = float2(sin(rotation), cos(rotation));
    return gradientNoise(pos, scale, float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y), seed);
}

// 2D Gradient noise with derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 gradientNoised(float2 pos, float2 scale, float seed) 
{
    // gradient noise with derivatives based on Inigo Quilez
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;
    
    float4 hashX, hashY;
    smultiHash2D(i, hashX, hashY);
    float2 a = float2(hashX.x, hashY.x);
    float2 b = float2(hashX.y, hashY.y);
    float2 c = float2(hashX.z, hashY.z);
    float2 d = float2(hashX.w, hashY.w);
    
    float4 gradients = hashX * f.xzxz + hashY * f.yyww;

    float4 udu = noiseInterpolateDu(f.xy);
    float2 u = udu.xy;
    float2 g = mix(gradients.xz, gradients.yw, u.x);
    
    float2 dxdy = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);
    dxdy += udu.zw * (u.yx * (gradients.x - gradients.y - gradients.z + gradients.w) + gradients.yz - gradients.x);
    return float3(mix(g.x, g.y, u.y) * 1.4142135623730950, dxdy);
}

// 2D Gradient noise with gradients transform (i.e. can be used to rotate the gradients) and derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param transform Transform matrix for the noise gradients.
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 gradientNoised(float2 pos, float2 scale, float2x2 transform, float seed) 
{
    // gradient noise with derivatives based on Inigo Quilez
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;
    
    float4 hashX, hashY;
    smultiHash2D(i, hashX, hashY);

    // transform gradients
    float4 m = float4(transform);
    float4 rh = float4(hashX.x, hashY.x, hashX.y, hashY.y);
    rh = rh.xxzz * m.xyxy + rh.yyww * m.zwzw;
    hashX.xy = rh.xz;
    hashY.xy = rh.yw;

    rh = float4(hashX.z, hashY.z, hashX.w, hashY.w);
    rh = rh.xxzz * m.xyxy + rh.yyww * m.zwzw;
    hashX.zw = rh.xz;
    hashY.zw = rh.yw;
    
    float2 a = float2(hashX.x, hashY.x);
    float2 b = float2(hashX.y, hashY.y);
    float2 c = float2(hashX.z, hashY.z);
    float2 d = float2(hashX.w, hashY.w);
    
    float4 gradients = hashX * f.xzxz + hashY * f.yyww;

    float4 udu = noiseInterpolateDu(f.xy);
    float2 u = udu.xy;
    float2 g = mix(gradients.xz, gradients.yw, u.x);
    
    float2 dxdy = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);
    dxdy += udu.zw * (u.yx * (gradients.x - gradients.y - gradients.z + gradients.w) + gradients.yz - gradients.x);
    return float3(mix(g.x, g.y, u.y) * 1.4142135623730950, dxdy);
}

// 2D Gradient noise with gradients rotation and derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param rotation Rotation for the noise gradients, useful to animate flow, range: [0, PI]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 gradientNoised(float2 pos, float2 scale, float rotation, float seed) 
{
    float2 sinCos = float2(sin(rotation), cos(rotation));
    return gradientNoised(pos, scale, float2x2(sinCos.y, sinCos.x, sinCos.x, sinCos.y), seed);
}

// Variant of 2D Gradient noise with disorder/jitter for the gradients.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param disoder Jitter factor for the noise gradients,, range: [0, 1.0]
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float gradientNoiseDisorder(float2 pos, float2 scale, float disoder, float seed) 
{
    pos *= scale;
    float4 i = floor(pos).xyxy + float2(0.0, 1.0).xxyy;
    float4 f = (pos.xyxy - i.xyxy) - float2(0.0, 1.0).xxyy;
    i = mod(i, scale.xyxy) + seed;

    float4 hashX, hashY;
    multiHash2D(i, hashX, hashY);
    hashX = (hashX * disoder) * 2.0 - 1.0;
    hashY = (hashY * disoder) * 2.0 - 1.0;

    float4 gradients = hashX * f.xzxz + hashY * f.yyww;
    float2 u = noiseInterpolate(f.xy);
    float2 g = mix(gradients.xz, gradients.yw, u.x);
    return 1.4142135623730950 * mix(g.x, g.y, u.y);
}
