// Classic 3x3 Cellular noise with F1 and F2 distances.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Returns the cellular distances, x = F1, y = F2, range: [0, 1].
float2 cellularNoise(float2 pos, float2 scale, float jitter, float seed) 
{       
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = fmod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = dx0 * dx0 + dy0 * dy0; 
    float4 d1 = dx1 * dx1 + dy1 * dy1; 
    
    float2 centerPos = multiHash2D(i) * jitter - f; // 0 0
    
    float4 F = min(d0, d1);
    // shuffle into F the 4 lowest values
    F = min(F, max(d0, d1).wzyx);
    // shuffle into F the 2 lowest values 
    F.xy = min(min(F.xy, F.zw), max(F.xy, F.zw).yx);
    // add the last value
    F.zw = float2(dot(centerPos, centerPos), 1e+5);
    // shuffle into F the final 2 lowest values 
    F.xy = min(min(F.xy, F.zw), max(F.xy, F.zw).yx);
    
    float2 f12 = float2(min(F.x, F.y), max(F.x, F.y));
    // normalize: 0.75^2 * 2.0  == 1.125
    return sqrt(f12) * (1.0 / 1.125);
}

// Classic 3x3 Cellular noise with F1 and F2 distances.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Returns the cellular distances, x = F1, y = F2, range: [0, 1].
float2 cellularNoise(float2 pos, float2 scale, float jitter, float phase, float seed) 
{        
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    dx0 = 0.5 * sin(phase + kPI2 * dx0) + 0.5;
    dy0 = 0.5 * sin(phase + kPI2 * dy0) + 0.5;
    dx1 = 0.5 * sin(phase + kPI2 * dx1) + 0.5;
    dy1 = 0.5 * sin(phase + kPI2 * dy1) + 0.5;
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = dx0 * dx0 + dy0 * dy0; 
    float4 d1 = dx1 * dx1 + dy1 * dy1; 
    
    float2 centerPos = (0.5 * sin(phase + kPI2 * multiHash2D(i)) + 0.5) * jitter - f; // 0 0
    float4 F = min(d0, d1);
    // shuffle into F the 4 lowest values
    F = min(F, max(d0, d1).wzyx);
    // shuffle into F the 2 lowest values 
    F.xy = min(min(F.xy, F.zw), max(F.xy, F.zw).yx);
    // add the last value
    F.zw = float2(dot(centerPos, centerPos), 1e+5);
    // shuffle into F the final 2 lowest values 
    F.xy = min(min(F.xy, F.zw), max(F.xy, F.zw).yx);
    
    float2 f12 = float2(min(F.x, F.y), max(F.x, F.y));
    // normalize: 0.75^2 * 2.0  == 1.125
    return sqrt(f12) * (1.0 / 1.125);
}

// Classic 3x3 Cellular noise with F1 and F2 distances with support for multiple metrics.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param metric The distance metric used, can be euclidean, manhattan, chebyshev or triangular, range: [0, 3], default: 0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Returns the cellular distances, x = F1, y = F2, range: [0, 1].
float2 cellularNoise(float2 pos, float2 scale, float jitter, float phase, uint metric, float seed) 
{       
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    dx0 = 0.5 * sin(phase + kPI2 * dx0) + 0.5;
    dy0 = 0.5 * sin(phase + kPI2 * dy0) + 0.5;
    dx1 = 0.5 * sin(phase + kPI2 * dx1) + 0.5;
    dy1 = 0.5 * sin(phase + kPI2 * dy1) + 0.5;
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = distanceMetric(dx0, dy0, metric);
    float4 d1 = distanceMetric(dx1, dy1, metric);
    
    float2 centerPos = (0.5 * sin(phase + kPI2 * multiHash2D(i)) + 0.5) * jitter - f; // 0 0
    float4 F = min(d0, d1);
    // shuffle into F the 4 lowest values
    F = min(F, max(d0, d1).wzyx);
    // shuffle into F the 2 lowest values 
    F.xy = min(min(F.xy, F.zw), max(F.xy, F.zw).yx);
    // add the last value
    F.zw = float2(distanceMetric(centerPos, metric), 1e+5);
    // shuffle into F the final 2 lowest values 
    F.xy = min(min(F.xy, F.zw), max(F.xy, F.zw).yx);
    
    float2 f12 = float2(min(F.x, F.y), max(F.x, F.y));
    // normalize: 0.75^2 * 2.0  == 1.125
    return (metric == 0u ? sqrt(f12) : f12) * (1.0 / 1.125);
}

// Classic 3x3 Cellular noise with F1 and F2 distances and derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 cellularNoised(float2 pos, float2 scale, float jitter, float seed) 
{       
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = dx0 * dx0 + dy0 * dy0; 
    float4 d1 = dx1 * dx1 + dy1 * dy1; 
    
    float2 centerPos = multiHash2D(i) * jitter - f; // 0 0
    float dCenter = dot(centerPos, centerPos);
    float4 d = min(d0, d1);
    float4 less = step(d1, d0);
    float4 dx = mix(dx0, dx1, less);
    float4 dy = mix(dy0, dy1, less);

    float3 t1 = d.x < d.y ? float3(d.x, dx.x, dy.x) : float3(d.y, dx.y, dy.y);
    float3 t2 = d.z < d.w ? float3(d.z, dx.z, dy.z) : float3(d.w, dx.w, dy.w);
    t2 = t2.x < dCenter ? t2 : float3(dCenter, centerPos);
    float3 t = t1.x < t2.x ? t1 : t2;
    t.x = sqrt(t.x);
    // normalize: 0.75^2 * 2.0  == 1.125
    return  t * float3(1.0, -2.0, -2.0) * (1.0 / 1.125);
}

// Classic 3x3 Cellular noise with F1 and F2 distances and derivatives.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return x = value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 cellularNoised(float2 pos, float2 scale, float jitter, float phase, float seed) 
{       
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    dx0 = 0.5 * sin(phase + kPI2 * dx0) + 0.5;
    dy0 = 0.5 * sin(phase + kPI2 * dy0) + 0.5;
    dx1 = 0.5 * sin(phase + kPI2 * dx1) + 0.5;
    dy1 = 0.5 * sin(phase + kPI2 * dy1) + 0.5;
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = dx0 * dx0 + dy0 * dy0; 
    float4 d1 = dx1 * dx1 + dy1 * dy1; 
    
    float2 centerPos = (0.5 * sin(phase + kPI2 * multiHash2D(i)) + 0.5) * jitter - f; // 0 0
    float dCenter = dot(centerPos, centerPos);
    float4 d = min(d0, d1);
    float4 less = step(d1, d0);
    float4 dx = mix(dx0, dx1, less);
    float4 dy = mix(dy0, dy1, less);

    float3 t1 = d.x < d.y ? float3(d.x, dx.x, dy.x) : float3(d.y, dx.y, dy.y);
    float3 t2 = d.z < d.w ? float3(d.z, dx.z, dy.z) : float3(d.w, dx.w, dy.w);
    t2 = t2.x < dCenter ? t2 : float3(dCenter, centerPos);
    float3 t = t1.x < t2.x ? t1 : t2;
    t.x = sqrt(t.x);
    // normalize: 0.75^2 * 2.0  == 1.125
    return  t * float3(1.0, -2.0, -2.0) * (1.0 / 1.125);
}

// A variation of 3x3 Cellular noise that multiplies the minimum distance between the cells.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Returns the metaballs distance from the cell edges, range: [0, 1]
float metaballs(float2 pos, float2 scale, float jitter, float seed) 
{       
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);

    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = dx0 * dx0 + dy0 * dy0; 
    float4 d1 = dx1 * dx1 + dy1 * dy1; 
    
    float2 centerPos = multiHash2D(i) * jitter - f; // 0 0
    
    float d = min(1.0, dot(centerPos, centerPos));
    d = min(d, d * d0.x);
    d = min(d, d * d0.y);
    d = min(d, d * d0.z);
    d = min(d, d * d0.w);
    d = min(d, d * d1.x);
    d = min(d, d * d1.y);
    d = min(d, d * d1.z);
    d = min(d, d * d1.w);
    
    return sqrt(d);
}

float metaballs(float2 pos, float2 scale, float jitter, float width, float smoothness, float seed) 
{       
    float d = metaballs(pos, scale, jitter, seed);
    return smoothstep(width, width + smoothness, d);
}

// A variation of 3x3 Cellular noise that multiplies the minimum distance between the cells.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Returns the metaballs distance from the cell edges, range: [0, 1]
float metaballs(float2 pos, float2 scale, float jitter, float phase, float seed) 
{       
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    dx0 = 0.5 * sin(phase + kPI2 * dx0) + 0.5;
    dy0 = 0.5 * sin(phase + kPI2 * dy0) + 0.5;
    dx1 = 0.5 * sin(phase + kPI2 * dx1) + 0.5;
    dy1 = 0.5 * sin(phase + kPI2 * dy1) + 0.5;
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = dx0 * dx0 + dy0 * dy0; 
    float4 d1 = dx1 * dx1 + dy1 * dy1; 
    
    float2 centerPos = (0.5 * sin(phase + kPI2 * multiHash2D(i)) + 0.5) * jitter - f; // 0 0
    
    float d = min(1.0, dot(centerPos, centerPos));
    d = min(d, d * d0.x);
    d = min(d, d * d0.y);
    d = min(d, d * d0.z);
    d = min(d, d * d0.w);
    d = min(d, d * d1.x);
    d = min(d, d * d1.y);
    d = min(d, d * d1.z);
    d = min(d, d * d1.w);
    
    return sqrt(d);
}

float metaballs(float2 pos, float2 scale, float jitter, float phase, float width, float smoothness, float seed) 
{       
    float d = metaballs(pos, scale, jitter, phase, seed);
    return smoothstep(width, width + smoothness, d);
}

// A variation of 3x3 Cellular noise that multiplies the minimum distance between the cells.
// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param metric The distance metric used, can be euclidean, manhattan, chebyshev or triangular, range: [0, 3], default: 0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return Returns the metaballs distance from the cell edges, range: [0, 1]
float metaballs(float2 pos, float2 scale, float jitter, float phase, uint metric, float seed) 
{       
    const float kPI2 = 6.2831853071;
    pos *= scale;
    float2 i = floor(pos);
    float2 f = pos - i;
    
    const float3 offset = float3(-1.0, 0.0, 1.0);
    float4 cells = mod(i.xyxy + offset.xxzz, scale.xyxy) + seed;
    i = mod(i, scale) + seed;
    float4 dx0, dy0, dx1, dy1;
    multiHash2D(float4(cells.xy, float2(i.x, cells.y)), float4(cells.zyx, i.y), dx0, dy0);
    multiHash2D(float4(cells.zwz, i.y), float4(cells.xw, float2(i.x, cells.w)), dx1, dy1);
    dx0 = 0.5 * sin(phase + kPI2 * dx0) + 0.5;
    dy0 = 0.5 * sin(phase + kPI2 * dy0) + 0.5;
    dx1 = 0.5 * sin(phase + kPI2 * dx1) + 0.5;
    dy1 = 0.5 * sin(phase + kPI2 * dy1) + 0.5;
    
    dx0 = offset.xyzx + dx0 * jitter - f.xxxx; // -1 0 1 -1
    dy0 = offset.xxxy + dy0 * jitter - f.yyyy; // -1 -1 -1 0
    dx1 = offset.zzxy + dx1 * jitter - f.xxxx; // 1 1 -1 0
    dy1 = offset.zyzz + dy1 * jitter - f.yyyy; // 1 0 1 1
    float4 d0 = distanceMetric(dx0, dy0, metric);
    float4 d1 = distanceMetric(dx1, dy1, metric);
    
    float2 centerPos = (0.5 * sin(phase + kPI2 * multiHash2D(i)) + 0.5) * jitter - f; // 0 0
    
    float d = min(1.0, distanceMetric(centerPos, metric));
    d = min(d, d * d0.x);
    d = min(d, d * d0.y);
    d = min(d, d * d0.z);
    d = min(d, d * d0.w);
    d = min(d, d * d1.x);
    d = min(d, d * d1.y);
    d = min(d, d * d1.z);
    d = min(d, d * d1.w);
    
    return metric == 0u ? sqrt(d) : d;
}

float metaballs(float2 pos, float2 scale, float jitter, float phase, float width, float smoothness, uint metric, float seed) 
{       
    float d = metaballs(pos, scale, jitter, phase, metric, seed);
    return smoothstep(width, width + smoothness, d);
}

// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param metric The distance metric used, can be euclidean, manhattan, chebyshev or triangular, range: [0, 3], default: 0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise
float3 crystals(float2 pos, float2 scale, float jitter, float phase, uint metric)
{
    float3 c0, c1;
    c0.xy = cellularNoise(pos, scale, jitter, phase, metric, 0.0);
    c1.xy = cellularNoise(pos, scale, jitter, phase, metric, 23.0);
    c0.x = 1.0 - c0.x;
    c1.x = 1.0 - c1.x;
    if (c0.x > c1.x)
    {
        float3 temp = c0;
        c0 = c1;
        c1 = temp;
    }

    return float3(c1.x - c0.x, c0.yz - c1.yz);
}

// @param scale Number of tiles, must be  integer for tileable results, range: [2, inf]
// @param jitter Jitter factor for the cells, if zero then it will result in a square grid, range: [0, 1], default: 1.0
// @param phase The phase for rotating the cells, range: [0, inf], default: 0.0
// @param seed Seed to randomize result, range: [0, inf], default: 0.0
// @return value of the noise, yz = derivative of the noise, range: [-1, 1]
float3 crystalsd(float2 pos, float2 scale, float jitter, float phase)
{
    float3 c0 = cellularNoised(pos, scale, jitter, phase, 0.0);
    float3 c1 = cellularNoised(pos, scale, jitter, phase, 23.0);
    c0.x = 1.0 - c0.x;
    c1.x = 1.0 - c1.x;
    if (c0.x > c1.x)
    {
        float3 temp = c0;
        c0 = c1;
        c1 = temp;
    }

    return float3(c1.x - c0.x, c0.yz - c1.yz);
}
