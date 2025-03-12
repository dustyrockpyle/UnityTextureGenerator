#define mod(x, y) ((x) - (y) * floor((x) / (y)))
#define mix lerp

float2 comp2(float x)
{
    return float2(x, x);
}

float3 comp3(float x)
{
    return float3(x, x, x);
}

float4 comp4(float x)
{
    return float4(x, x, x, x);
}

#include "Assets/Shaders/Noise/ProceduralTileableShaders/hash.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/multiHash.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/metric.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/interpolate.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/noise.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/cellularNoise.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/perlinNoise.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/gradientNoise.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/voronoi.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/fbm.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/fbmImage.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/patterns.hlsl"
#include "Assets/Shaders/Noise/ProceduralTileableShaders/warp.hlsl"
