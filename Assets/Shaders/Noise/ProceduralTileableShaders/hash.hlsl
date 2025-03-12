
uint ihash1D(uint q)
{
    // hash by Hugo Elias, Integer Hash - I, 2017
    q = (q << 13u) ^ q;
    return q * (q * q * 15731u + 789221u) + 1376312589u;
}

uint2 ihash1D(uint2 q)
{
    // hash by Hugo Elias, Integer Hash - I, 2017
    q = (q << 13u) ^ q;
    return q * (q * q * 15731u + 789221u) + 1376312589u;
}

uint4 ihash1D(uint4 q)
{
    // hash by Hugo Elias, Integer Hash - I, 2017
    q = (q << 13u) ^ q;
    return q * (q * q * 15731u + 789221u) + 1376312589u;
}

// @return Value of the noise, range: [0, 1]
float hash1D(float x)
{
    // based on: pcg by Mark Jarzynski: http://www.jcgt.org/published/0009/03/02/
    uint state = uint(x * 8192.0) * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return float((word >> 22u) ^ word) * (1.0 / float(0xffffffffu));;
}

// @return Value of the noise, range: [0, 1]
float hash1D(float2 x)
{
    // hash by Inigo Quilez, Integer Hash - III, 2017
    uint2 q = uint2(x * 8192.0);
    q = 1103515245u * ((q >> 1u) ^ q.yx);
    uint n = 1103515245u * (q.x ^ (q.y >> 3u));
    return float(n) * (1.0 / float(0xffffffffu));
}

// @return Value of the noise, range: [0, 1]
float hash1D(float3 x)
{
    // based on: pcg3 by Mark Jarzynski: http://www.jcgt.org/published/0009/03/02/
    uint3 v = uint3(x * 8192.0) * 1664525u + 1013904223u;
    v += v.yzx * v.zxy;
    v ^= v >> 16u;
    return float(v.x + v.y * v.z) * (1.0 / float(0xffffffffu));
}

// @return Value of the noise, range: [0, 1]
float2 hash2D(float2 x)
{
    // based on: Inigo Quilez, Integer Hash - III, 2017
    uint4 q = uint2(x * 8192.0).xyyx + uint2(0u, 3115245u).xxyy;
    q = 1103515245u * ((q >> 1u) ^ q.yxwz);
    uint2 n = 1103515245u * (q.xz ^ (q.yw >> 3u));
    return float2(n) * (1.0 / float(0xffffffffu));
}

// @return Value of the noise, range: [0, 1]
float3 hash3D(float2 x) 
{
    // based on: pcg3 by Mark Jarzynski: http://www.jcgt.org/published/0009/03/02/
    uint3 v = uint3(x.xyx * 8192.0) * 1664525u + 1013904223u;
    v += v.yzx * v.zxy;
    v ^= v >> 16u;

    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return float3(v) * (1.0 / float(0xffffffffu));
}

// @return Value of the noise, range: [0, 1]
float3 hash3D(float3 x) 
{
    // based on: pcg3 by Mark Jarzynski: http://www.jcgt.org/published/0009/03/02/
    uint3 v = uint3(x * 8192.0) * 1664525u + 1013904223u;
    v += v.yzx * v.zxy;
    v ^= v >> 16u;

    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return float3(v) * (1.0 / float(0xffffffffu));
}

// @return Value of the noise, range: [0, 1]
float4 hash4D(float2 x)
{
    // based on: pcg4 by Mark Jarzynski: http://www.jcgt.org/published/0009/03/02/
    uint4 v = uint4(x.xyyx * 8192.0) * 1664525u + 1013904223u;

    v += v.yzxy * v.wxyz;
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    
    v.x += v.y * v.w;
    v.w += v.y * v.z;
    
    v ^= v >> 16u;

    return float4(v ^ (v >> 16u)) * (1.0 / float(0xffffffffu));
}

// @return Value of the noise, range: [0, 1]
float4 hash4D(float4 x)
{
    // based on: pcg4 by Mark Jarzynski: http://www.jcgt.org/published/0009/03/02/
    uint4 v = uint4(x * 8192.0) * 1664525u + 1013904223u;

    v += v.yzxy * v.wxyz;
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;

    v ^= v >> 16u;

    return float4(v ^ (v >> 16u)) * (1.0 / float(0xffffffffu));
}
