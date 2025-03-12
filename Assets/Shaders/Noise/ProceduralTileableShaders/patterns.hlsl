float3 checkerboard(const in float2 pos, const in float2 scale, const in float2 smoothness)
{
    // based on filtering the checkerboard by Inigo Quilez 
    float2 numTiles = floor(scale); 
    float2 p = pos * numTiles * 2.0;
    float2 tile = mod(floor(p), numTiles * 2.0);
    
    float2 w = max(smoothness, comp2(0.001));
    // box filter using triangular signal
    float2 s1 = abs(frac((p - 0.5 * w) / 2.0) - 0.5);
    float2 s2 = abs(frac((p + 0.5 * w) / 2.0) - 0.5);
    float2 i = 2.0 * (s1 - s2) / w;
    float d = 0.5 - 0.5 * i.x * i.y; // xor pattern
    return float3(d, tile);
}

float3 checkerboard45(const in float2 pos, const in float2 scale, const in float2 smoothness)
{
    // based on filtering the checkerboard by Inigo Quilez 
    const float sqrtOfTwo = 1.41421356237;
    
    float2 numTiles = floor(scale); 
    float2 p = pos * numTiles * 2.0;
    
    const float2x2 rotate45 = float2x2(0.70710678119, 0.70710678119, -0.70710678119, 0.70710678119);
    p *= 1.0 / sqrtOfTwo;
    p.x += sqrtOfTwo * 0.5;
    p = mul(rotate45, p);

    float2 w = max(smoothness, comp2(0.001));
    // box filter using triangular signal
    float2 s1 = abs(frac((p - 0.5 * w) / 2.0) - 0.5);
    float2 s2 = abs(frac((p + 0.5 * w) / 2.0) - 0.5);
    float2 i = 2.0 * (s1 - s2) / w;
    float d = 0.5 - 0.5 * i.x * i.y; // xor pattern
    float2 tile = mod(floor(p), numTiles);
    return float3(d, tile);
}

float triangleWave(float x) 
{
    const float pi = 3.141592;
    float t = x / (pi * 2.0) + pi / 4.0;
    return abs(frac(t) * 2.0 - 1.0) * 2.0 - 1.0;
}

float wavePattern(float2 pos, float2 scale, float width, float smoothness, float amplitude, float interpolate)
{
    scale = floor(scale);
    const float pi = 3.141592;
    float2 p;
    p.x = pos.x * pi * scale.x;
    p.y = pos.y * scale.y;
    
    float sy = p.y + amplitude * mix(triangleWave(p.x), sin(p.x), interpolate);
    float t = triangleWave(sy * scale.y * pi * 0.25);
    return 1.0 - smoothstep(max(width - smoothness, 0.0), width, t * 0.5 + 0.5);
}

float crossPattern(float2 pos, float2 scale, float2 smoothness)
{
    scale = floor(scale);
    float2 p = pos * scale;
    
    const float N = 3.0;
    float2 w = max(smoothness, comp2(0.001));
    float2 halfW = 0.5 * w;
    float2 a = p + halfW;                        
    float2 b = p - halfW;  
    
    float2 x = floor(a) + min(frac(a) * N, 1.0) - floor(b) - min(frac(b) * N, 1.0);
    float2 i = x / (N * w);
    return 1.0 - i.x - i.y + 2.0 * i.x * i.y;
}

float stairsPattern(float2 pos, float2 scale, float width, float smoothness, float distance)   
{
    float2 p = pos * scale;
    float2 f = frac(p);
    
    float2 m = floor(mod(p, comp2(2.0)));
    float d = mix(f.x, f.y, abs(m.x - m.y));
    d = mix(d, abs(d * 2.0 - 1.0), distance);
    
    return 1.0 - smoothstep(max(width - smoothness, 0.0), width, d);        
}

float sdfLens(float2 p, float width, float height)
{
    // Vesica SDF based on Inigo Quilez
    float d = height / width - width / 4.0;
    float r = width / 2.0 + d;
    
    p = abs(p);

    float b = sqrt(r * r - d * d);
    float4 par = p.xyxy - float4(0.0, b, -d, 0.0);
    return (par.y * d > p.x * b) ? length(par.xy) : length(par.zw) - r;
}

float3 tileWeave(float2 pos, float2 scale, float count, float width, float smoothness)
{
    float2 i = floor(pos * scale);    
    float c = mod(i.x + i.y, 2.0);
    
    float2 p = frac(pos.xy * scale);
    p = mix(p.xy, p.yx, c);
    p = frac(p * float2(count, 1.0));
    
    width *= 2.0;
    p = p * 2.0 - 1.0;
    float d = sdfLens(p, width, 1.0);
    float2 grad = float2(ddx(d), ddy(d));

    float s = 1.0 - smoothstep(0.0, dot(abs(grad), comp2(1.0)) + smoothness, -d);
    return float3(s, normalize(grad) * smoothstep(1.0, 0.99, s) * smoothstep(0.0, 0.01, s)); 
}

float sdfCapsule(float2 p, float radiusA, float radiusB, float height)
{
    // Capsule SDF based on Inigo Quilez
    p.x = abs(p.x);
    p.y += height * 0.5;
    
    float b = (radiusA - radiusB) / height;
    float2 c = float2(sqrt(1.0 - b * b), b);
    float3 mnk = float3(c.x, p.x, c.x) * p.xxy + float3(c.y, p.y, -c.y) * p.yyx;
    
    if( mnk.z < 0.0   ) 
        return sqrt(mnk.y) - radiusA;
    else if(mnk.z > c.x * height) 
        return sqrt(mnk.y + height * height - 2.0 * height * p.y) - radiusB;
    return mnk.x - radiusA;
}
float3 tileWeave(float2 pos, float2 scale, float count, float2 width, float smoothness)
{
    float2 i = floor(pos * scale);    
    float c = mod(i.x + i.y, 2.0);
    
    float2 p = frac(pos.xy * scale);
    p = mix(p.xy, p.yx, c);
    p = frac(p * float2(count, 1.0));
    
    p = p * 2.0 - 1.0;
    float d = sdfCapsule(p, width.x, width.y, 1.0 - max(width.x, width.y) * 0.75);
    float2 grad = float2(ddx(d), ddy(d));

    float s = 1.0 - smoothstep(0.0, dot(abs(grad), comp2(1.0)) + smoothness, -d);
    return float3(s, normalize(grad) * smoothstep(1.0, 0.99, s) * smoothstep(0.0, 0.01, s)); 
}
