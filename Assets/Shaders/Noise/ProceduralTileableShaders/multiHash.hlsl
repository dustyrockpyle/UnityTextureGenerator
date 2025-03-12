
// based on GPU Texture-Free Noise by Brian Sharpe: https://archive.is/Hn54S
float3 permutePrepareMod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float4 permutePrepareMod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float4 permuteResolve(float4 x) { return frac( x * (7.0 / 288.0 )); }
float4 permuteHashInternal(float4 x) { return frac(x * ((34.0 / 289.0) * x + (1.0 / 289.0))) * 289.0; }

// generates a random number for each of the 4 cell corners
float4 permuteHash2D(float4 cell)    
{
    cell = permutePrepareMod289(cell * 32.0);
    return permuteResolve(permuteHashInternal(permuteHashInternal(cell.xzxz) + cell.yyww));
}

// generates 2 random numbers for each of the 4 cell corners
void permuteHash2D(float4 cell, out float4 hashX, out float4 hashY)
{
    cell = permutePrepareMod289(cell);
    hashX = permuteHashInternal(permuteHashInternal(cell.xzxz) + cell.yyww);
    hashY = permuteResolve(permuteHashInternal(hashX));
    hashX = permuteResolve(hashX);
}

// generates 2 random numbers for the coordinate
float2 betterHash2D(float2 x)
{
    uint2 q = uint2(x);
    uint h0 = ihash1D(ihash1D(q.x) + q.y);
    uint h1 = h0 * 1933247u + ~h0 ^ 230123u;
    return float2(h0, h1)  * (1.0 / float(0xffffffffu));
}

// generates a random number for each of the 4 cell corners
float4 betterHash2D(float4 cell)    
{
    uint4 i = uint4(cell);
    uint4 hash = ihash1D(ihash1D(i.xzxz) + i.yyww);
    return float4(hash) * (1.0 / float(0xffffffffu));
}

// generates 2 random numbers for each of the 4 cell corners
void betterHash2D(float4 cell, out float4 hashX, out float4 hashY)
{
    uint4 i = uint4(cell);
    uint4 hash0 = ihash1D(ihash1D(i.xzxz) + i.yyww);
    uint4 hash1 = ihash1D(hash0 ^ 1933247u);
    hashX = float4(hash0) * (1.0 / float(0xffffffffu));
    hashY = float4(hash1) * (1.0 / float(0xffffffffu));
}

// generates 2 random numbers for each of the 2D coordinates
float4 betterHash2D(float2 coords0, float2 coords1)
{
    uint4 i = uint4(coords0, coords1);
    uint4 hash = ihash1D(ihash1D(i.xz) + i.yw).xxyy;
    hash.yw = hash.yw * 1933247u + ~hash.yw ^ 230123u;
    return float4(hash) * (1.0 / float(0xffffffffu));;
}

// generates 2 random numbers for each of the four 2D coordinates
void betterHash2D(float4 coords0, float4 coords1, out float4 hashX, out float4 hashY)
{
    uint4 hash0 = ihash1D(ihash1D(uint4(coords0.xz, coords1.xz)) + uint4(coords0.yw, coords1.yw));
    uint4 hash1 = hash0 * 1933247u + ~hash0 ^ 230123u;
    hashX = float4(hash0) * (1.0 / float(0xffffffffu));
    hashY = float4(hash1) * (1.0 / float(0xffffffffu));
} 

// 3D

// generates a random number for each of the 8 cell corners
void permuteHash3D(float3 cell, float3 cellPlusOne, out float4 lowHash, out float4 highHash)     
{
    cell = permutePrepareMod289(cell);
    cellPlusOne = step(cell, comp3(287.5)) * cellPlusOne;

    highHash = permuteHashInternal(permuteHashInternal(float2(cell.x, cellPlusOne.x).xyxy) + float2(cell.y, cellPlusOne.y).xxyy);
    lowHash = permuteResolve(permuteHashInternal(highHash + cell.zzzz));
    highHash = permuteResolve(permuteHashInternal(highHash + cellPlusOne.zzzz));
}

// generates a random number for each of the 8 cell corners
void fastHash3D(float3 cell, float3 cellPlusOne, out float4 lowHash, out float4 highHash)
{
    // based on: https://archive.is/wip/7j1wv
    const float2 kOffset = float2(50.0, 161.0);
    const float kDomainScale = 289.0;
    const float kLargeValue = 635.298681;
    const float kk = 48.500388;
    
    //truncate the domain, equivalant to mod(cell, kDomainScale)
    cell -= floor(cell.xyz * (1.0 / kDomainScale)) * kDomainScale;
    cellPlusOne = step(cell, comp3(kDomainScale - 1.5)) * cellPlusOne;

    float4 r = float4(cell.xy, cellPlusOne.xy) + kOffset.xyxy;
    r *= r;
    r = r.xzxz * r.yyww;
    highHash.xy = float2(1.0 / (kLargeValue + float2(cell.z, cellPlusOne.z) * kk));
    lowHash = frac(r * highHash.xxxx);
    highHash = frac(r * highHash.yyyy);
}

// generates a random number for each of the 8 cell corners
void betterHash3D(float3 cell, float3 cellPlusOne, out float4 lowHash, out float4 highHash)
{
    uint4 cells = uint4(cell.xy, cellPlusOne.xy);  
    uint4 hash = ihash1D(ihash1D(cells.xzxz) + cells.yyww);
    
    lowHash = float4(ihash1D(hash + uint(cell.z))) * (1.0 / float(0xffffffffu));
    highHash = float4(ihash1D(hash + uint(cellPlusOne.z))) * (1.0 / float(0xffffffffu));
}

// @note Can change to (faster to slower order): permuteHash2D, betterHash2D
// Each has a tradeoff between quality and speed, some may also experience artifacts for certain ranges and are not realiable.
#define multiHash2D betterHash2D

// @note Can change to (faster to slower order): fastHash3D, permuteHash3D, betterHash3D
// Each has a tradeoff between quality and speed, some may also experience artifacts for certain ranges and are not realiable.
#define multiHash3D betterHash3D

void smultiHash2D(float4 cell, out float4 hashX, out float4 hashY)
{
    multiHash2D(cell, hashX, hashY);
    hashX = hashX * 2.0 - 1.0; 
    hashY = hashY * 2.0 - 1.0;
}
