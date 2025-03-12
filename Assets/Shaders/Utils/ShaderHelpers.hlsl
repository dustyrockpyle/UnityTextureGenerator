#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

float2 FlipbookUv(float2 uv, float tile, float texWidth, float texHeight)
{
    float2 tileCount = float2(1.0, 1.0) / float2(texWidth, texHeight);
    float row = floor(tile * tileCount.x + .001);
    float tileY = texHeight - row - 1;
    float tileX = tile - texWidth * row;
    return (uv + float2(tileX, tileY)) * tileCount;
}

float invLerp(float start, float end, float x)
{
    return (x - start) / (end - start);
}

float2 invLerp(float2 start, float2 end, float2 x)
{
    return (x - start) / (end - start);
}

float invLerpSat(float start, float end, float x)
{
    return saturate(invLerp(start, end, x));
}

float2 invLerpSat(float2 start, float2 end, float2 x)
{
    return saturate(invLerp(start, end, x));
}

float LerpUnclamped(float a, float b, float t)
{
    return a + t * (b - a);
}

float LerpUnclamped(float2 a, float2 b, float2 t)
{
    return a + t * (b - a);
}

float LerpUnclamped(float3 a, float3 b, float3 t)
{
    return a + t * (b - a);
}

float LerpUnclamped(float4 a, float4 b, float4 t)
{
    return a + t * (b - a);
}

float GetRGBLuminanceLinear(float3 color) //.2126, 0.7152, 0.0722
{
    return (0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b);
}

float3 DesaturateLinear(float3 base, float factor = 1.0)
{
    float luminance = GetRGBLuminanceLinear(base);
    float maxVal = max(base.r, max(base.g, base.b));
    float3 newColor = float3(maxVal, maxVal, maxVal);
    float newLum = GetRGBLuminanceLinear(newColor);
    float lumDelta = luminance - newLum;
    newColor = float3(newColor.r + lumDelta, newColor.g + lumDelta, newColor.b + lumDelta);
    return lerp(base, newColor, factor);
}

float RiseFall(float midpoint, float target, float t)
{
    float rise = smoothstep(0, midpoint, t);
    float fall = smoothstep(midpoint, 1, t);
    return (rise - fall) * target;
}

float RiseFall(float start, float midpoint, float end, float target, float t)
{
    float rise = smoothstep(start, midpoint, t);
    float fall = smoothstep(midpoint, end, t);
    return (rise - fall) * target;
}

float Overshoot(float midpoint, float overshoot, float t)
{
    float rise = smoothstep(0, midpoint, t) * (1 + overshoot);
    float fall = smoothstep(midpoint, 1, t) * overshoot;
    return rise - fall;
}

float Overshoot(float start, float midpoint, float end, float overshoot, float t)
{
    float rise = smoothstep(start, midpoint, t) * (1 + overshoot);
    float fall = smoothstep(midpoint, end, t) * overshoot;
    return rise - fall;
}

float SmoothArc(float t, float midpoint)
{
    float rise = smoothstep(0, midpoint, t);
    float fall = smoothstep(midpoint, 1, t);
    return rise - fall;
}

float2 ComputeLightingUV(float4 positionCS)
{
    float4 clipVertex = positionCS / positionCS.w;
    return ComputeScreenPos(clipVertex).xy;
}

// Returns a value between 0 and 1
float Rand(float2 seed)
{
   return frac(sin(dot(seed.xy, float2(12.9898,78.233))) * 43758.5453);
}

// Returns a value between -1 and 1
float NegRand(float2 seed)
{
   return Rand(seed) * 2 - 1;
}

float RandTheta(float2 seed)
{
    return Rand(seed) * 6.283185;
}

float2 RotationFromAngle(float theta)
{
    return float2(cos(theta), sin(theta));
}

float2 RandDirection(float2 seed)
{
    float theta = RandTheta(seed);
    return float2(cos(theta), sin(theta));
}

float GetRandMagnitude(float2 seed, float min_magnitude, float max_magnitude)
{
    return min_magnitude + (max_magnitude - min_magnitude) * Rand(seed);
}

float2 RandVector(float2 seed, float min_magnitude, float max_magnitude)
{
    float2 direction = RandDirection(seed);
    float magnitude = GetRandMagnitude(seed * 64, min_magnitude, max_magnitude);
    return direction * magnitude;
}

float SqrDistance(float2 vec1, float2 vec2)
{
    float2 delta = vec2 - vec1;
    return dot(delta, delta);
}

float SqrMagnitude(float2 vec)
{
    return vec.x * vec.x + vec.y * vec.y;
}

float FastInvSqrt(float x)
{
    float xhalf = 0.5f * x;
    int i = asint(x);            // Convert float to int bits 
    i = 0x5f3759df - (i >> 1);   // Magic constant and bit-shift
    x = asfloat(i);              // Convert int bits back to float
    x *= 1.5f - (xhalf * x * x); // One Newton-Raphson iteration for refinement
    return x; 
}

float3 BaseSampleColor(int lod, float2 uv, float palette, Texture2D mainTex, SamplerState mainState, float2 mainTexel,
                       Texture2D colorTex, SamplerState colorState, float4 colorTexel)
{
    float2 minUv = (floor(uv / mainTexel.xy - .5) + .5) * mainTexel.xy;
    float2 maxUv = minUv + mainTexel.xy;
    float3 lowLeft = SAMPLE_TEXTURE2D_LOD(mainTex, mainState, minUv, lod).rgb;
    float3 lowRight = SAMPLE_TEXTURE2D_LOD(mainTex, mainState, float2(maxUv.x, minUv.y), lod).rgb;
    float3 upLeft = SAMPLE_TEXTURE2D_LOD(mainTex, mainState, float2(minUv.x, maxUv.y), lod).rgb;
    float3 upRight = SAMPLE_TEXTURE2D_LOD(mainTex, mainState, maxUv, lod).rgb;

    // Compensate for half texel offsets by mapping the range
    // from [0 - 1] to [.5 * ColorTexel.x - 1]
    lowLeft.x += lerp(.5, 0, lowLeft.x) * colorTexel.x;
    lowRight.x += lerp(.5, 0, lowRight.x) * colorTexel.x;
    upLeft.x += lerp(.5, 0, upLeft.x) * colorTexel.x;
    upRight.x += lerp(.5, 0, upRight.x) * colorTexel.x;

    float paletteV = colorTexel.y * (palette + .5);
    lowLeft.rgb = SAMPLE_TEXTURE2D(colorTex, colorState, float2(lowLeft.x, paletteV));
    lowRight.rgb = SAMPLE_TEXTURE2D(colorTex, colorState, float2(lowRight.x, paletteV));
    upLeft.rgb = SAMPLE_TEXTURE2D(colorTex, colorState, float2(upLeft.x, paletteV));
    upRight.rgb = SAMPLE_TEXTURE2D(colorTex, colorState, float2(upRight.x, paletteV));

    float2 lerpFrac = float2(invLerpSat(minUv.x, maxUv.x, uv.x), invLerpSat(minUv.y, maxUv.y, uv.y));
    float3 lowMix = lerp(lowLeft, lowRight, lerpFrac.x);
    float3 upMix = lerp(upLeft, upRight, lerpFrac.x);
    return lerp(lowMix, upMix, lerpFrac.y);
}

float ComputeMipLevel(float2 uv, float4 texelSize)
{
    float2 dX = ddx(uv * texelSize.zw);
    float2 dY = ddy(uv * texelSize.zw);
    float deltaMax = max(dot(dX, dX), dot(dY, dY));
    float mip = .5 * log2(deltaMax);
    return max(mip, 0);
}

float3 MultiplyPoint(float4x4 trs, float3 v)
{
    float3 result = trs._m00_m10_m20 * v.x + trs._m01_m11_m21 * v.y + trs._m02_m12_m22 * v.z;
    result += trs._m03_m13_m23;
    float num = 1.0 / ((trs._m30 *  v.x +  trs._m31 *  v.y +  trs._m32 *  v.z) + trs._m33);
    result *= num;
    return result;
}

float2 MultiplyPoint(float3x3 trs, float2 v)
{
    float2 result = trs._m00_m10 * v.x + trs._m01_m11 * v.y;
    result += trs._m02_m12;
    float num = 1.0 / ((trs._m20 * v.x + trs._m21 * v.y) + trs._m22);
    result *= num;
    return result;
}

// Example Usage:
//float4 color = SampleColor(uv, _Palette, _DiffuseTex, sampler_DiffuseTex, _DiffuseTex_TexelSize,
//                           _ColorPaletteTex, sampler_ColorPaletteTex, _ColorPaletteTex_TexelSize);
//float3 overlayColor = SampleColor(overlayUv, _OverlayPalette, _OverlayTex, sampler_OverlayTex,
//                      _OverlayTex_TexelSize, _OverlayColorPaletteTex, sampler_OverlayColorPaletteTex,
//                      _OverlayColorPaletteTex_TexelSize).rgb;
float4 SampleColor(float2 uv, float palette, Texture2D mainTex, SamplerState mainState, float4 mainTexel,
                   Texture2D colorTex, SamplerState colorState, float4 colorTexel)
{
    float lod = ComputeMipLevel(uv, mainTexel);
    int baseLod = floor(lod);
    float lpow = exp2(baseLod);
    mainTexel.xy *= lpow;
    float3 c0 = BaseSampleColor(baseLod, uv, palette, mainTex, mainState, mainTexel.xy,
                                colorTex, colorState, colorTexel);
    float3 c1 = BaseSampleColor(baseLod + 1, uv, palette, mainTex, mainState, mainTexel.xy * 2,
                                colorTex, colorState, colorTexel);
    float3 c2 = lerp(c0, c1, lod - baseLod);
    return float4(c2.r, c2.g, c2.b, 1);
}

float4 SampleColorAndAlpha(float2 uv, float palette, Texture2D mainTex, SamplerState mainState, float4 mainTexel,
                           Texture2D alphaTex, SamplerState alphaState,
                           Texture2D colorTex, SamplerState colorState, float4 colorTexel)
{
    float alpha = SAMPLE_TEXTURE2D(alphaTex, alphaState, uv);
    if (alpha == 0) return float4(0, 0, 0, 0);
    float lod = ComputeMipLevel(uv, mainTexel);
    int baseLod = floor(lod);
    float lpow = exp2(baseLod);
    mainTexel.xy *= lpow;
    float3 c0 = BaseSampleColor(baseLod, uv, palette, mainTex, mainState, mainTexel.xy,
                                colorTex, colorState, colorTexel);
    float3 c1 = BaseSampleColor(baseLod + 1, uv, palette, mainTex, mainState, mainTexel.xy * 2,
                                colorTex, colorState, colorTexel);
    float3 c2 = lerp(c0, c1, lod - baseLod);
    return float4(c2.r, c2.g, c2.b, alpha);
}

float4 SampleColorNoMips(float2 uv, float palette, Texture2D mainTex, SamplerState mainState, float4 mainTexel,
                   Texture2D colorTex, SamplerState colorState, float4 colorTexel)
{
    return float4(BaseSampleColor(0, uv, palette, mainTex, mainState, mainTexel,
                           colorTex, colorState, colorTexel), 1);
}

#define SAMPLE_COLOR(uv, palette, mapTex, colorTex) \
    SampleColor(uv, palette, mapTex, sampler##mapTex, ##mapTex##_TexelSize, \
                colorTex, sampler##colorTex, ##colorTex##_TexelSize)

#define SAMPLE_COLOR_ALPHA(uv, palette, mapTex, colorTex) \
    SampleColorAndAlpha(uv, palette, mapTex, sampler##mapTex, ##mapTex##_TexelSize, \
                        ##mapTex##Alpha, sampler##mapTex##Alpha, \
                        colorTex, sampler##colorTex, ##colorTex##_TexelSize)

#define SAMPLE_COLOR_NOMIPS(uv, palette, mapTex, colorTex) \
    SampleColorNoMips(uv, palette, mapTex, sampler##mapTex, ##mapTex##_TexelSize, \
                      colorTex, sampler##colorTex, ##colorTex##_TexelSize)

float3 UvToSphericalNormalWS(float2 uv)
{
    float2 coords = uv * 2 - 1;
    float2 sphereTS = normalize(coords);
    sphereTS = (sphereTS.xy + 1) * .5;
    return float3(sphereTS.x, sphereTS.y, 0);
}

float3 UvToSphericalNormalWS(float2 uv, float3 tangentWS, float3 bitangentWS)
{
    float2 coords = uv * 2 - 1;
    float3 sphereTS = 0;
    sphereTS.xy = normalize(coords);
    float3 normal = float3(0, 0, -1);
    float3 normalWS = mul(sphereTS, float3x3(tangentWS.xyz, bitangentWS.xyz, normal.xyz));
    normalWS = (normalWS + 1) * .5;
    return normalWS;
}

float3 UvToSphericalNormalWS(float2 uv, float3 tangentWS, float3 bitangentWS, float strength)
{
    float2 coords = uv * 2 - 1;
    float3 sphereTS = 0;
    sphereTS.xy = normalize(coords) * strength;
    float3 normal = float3(0, 0, -1);
    float3 normalWS = mul(sphereTS, float3x3(tangentWS.xyz, bitangentWS.xyz, normal.xyz));
    normalWS = (normalWS + 1) * .5;
    return normalWS;
}

struct StatefulParticleParentData
{
    float2 Position;
    float2 Velocity;
    int State;
    int Counter;
    int Palette;
    int IsFacingLeft;
};

struct BasicStatefulParticleData
{
    float2 Position;
    uint2 PackedUVDelta;
    uint PackedParentPositionDelta;
    uint PackedVelocity;
    uint ParticleFractionLifetimeFraction;
    uint PaletteStateCounter; // Palette & State & Counter packed together as 2 bytes and 1 short
};

float UnpackHalfTwo(uint packedHalf)
{
    return f16tof32((packedHalf & 0xFFFF0000) >> 16);
}

float UnpackHalfOne(uint packedHalf)
{
    return f16tof32(packedHalf & 0xFFFF);
}

float2 UnpackHalfs(uint packedHalf)
{
    return f16tof32(uint2(packedHalf, packedHalf >> 16));
}

float4 UnpackHalfs(uint2 packedHalf)
{
    uint2 shifted = packedHalf.xy >> 16;
    uint4 value = uint4(packedHalf.x, shifted.x, packedHalf.y, shifted.y);
    return f16tof32(value);
}

float2 GetParentPosition(BasicStatefulParticleData arg)
{
    uint2 value = uint2(arg.PackedParentPositionDelta >> 16, arg.PackedParentPositionDelta);
    float2 delta = f16tof32(value);
    return delta + arg.Position;
}

void SetParentPositionDelta(inout BasicStatefulParticleData arg, float2 parentPosition)
{
    float2 delta = parentPosition - arg.Position;
    uint2 value = f32tof16(delta);
    arg.PackedParentPositionDelta = (value.x << 16) + value.y;
}

float4 GetUVDelta(BasicStatefulParticleData arg)
{
    uint4 value = uint4(arg.PackedUVDelta.x >> 16, arg.PackedUVDelta.x, arg.PackedUVDelta.y >> 16, arg.PackedUVDelta.y);
    return f16tof32(value);
}

void SetUVDelta(inout BasicStatefulParticleData arg, float4 uvDelta)
{
    uint4 value = f32tof16(uvDelta);
    arg.PackedUVDelta = uint2((value.x << 16) + value.y, (value.z << 16) + value.w);
}

float2 GetVelocity(BasicStatefulParticleData arg)
{
    uint2 value = uint2(arg.PackedVelocity >> 16, arg.PackedVelocity);
    return f16tof32(value);
}

void SetVelocity(inout BasicStatefulParticleData arg, float2 velocity)
{
    uint2 value = f32tof16(velocity);
    arg.PackedVelocity = (value.x << 16) + value.y;
}

float GetParticleFraction(BasicStatefulParticleData arg)
{
    return (arg.ParticleFractionLifetimeFraction >> 16) / float(0xFFFF);
}

float GetLifetimeFraction(BasicStatefulParticleData arg)
{
    return (arg.ParticleFractionLifetimeFraction & 0xFFFF) / float(0xFFFF);
}

void SetParticleLifetimeFraction(inout BasicStatefulParticleData arg, float particleFrac, float lifetimeFrac)
{
    arg.ParticleFractionLifetimeFraction = (uint(particleFrac * 0xFFFF) << 16) + (uint(lifetimeFrac * 0xFFFF) & 0xFFFF);
}

void SetLifetimeFraction(inout BasicStatefulParticleData arg, float lifetimeFrac)
{
    arg.ParticleFractionLifetimeFraction = arg.ParticleFractionLifetimeFraction & 0xFFFF0000;
    arg.ParticleFractionLifetimeFraction += uint(saturate(lifetimeFrac) * 0xFFFF) & 0xFFFF;
}

int GetPalette(BasicStatefulParticleData arg)
{
    return (arg.PaletteStateCounter >> 24) & 0xFF;
}

int GetState(BasicStatefulParticleData arg)
{
    return (arg.PaletteStateCounter >> 16) & 0xF;
}

int GetModFrame(BasicStatefulParticleData arg)
{
    return (arg.PaletteStateCounter >> 20) & 0xF;
}

int GetCounter(BasicStatefulParticleData arg)
{
    return arg.PaletteStateCounter & 0xFFFF;
}

void SetPaletteFrameStateCounter(inout BasicStatefulParticleData arg, int palette, int frame, int state, int counter)
{
    arg.PaletteStateCounter = (palette << 24) + ((frame & 0xF) << 20) + (state << 16) + counter;
}

void SetFrameStateCounter(inout BasicStatefulParticleData arg, int frame, int state, int counter)
{
    arg.PaletteStateCounter = (arg.PaletteStateCounter & 0xFF000000) + ((frame & 0xF) << 20) + (state << 16) + counter;
}

float GetFrameDelta(BasicStatefulParticleData arg, float currentFrame)
{
    // Assumes ceil(currentFrame) >= particle frame
    int c1 = (int)ceil(currentFrame);
    int m1 = c1 & 0xF;
    int m2 = GetModFrame(arg);
    int delta = m1 - m2;
    delta += (delta < 0) * 16;
    int c2 = c1 - delta;
    return currentFrame - c2;
}

struct StatefulParticleGapFill
{
    int OldIndex;
    int NewIndex;
};

struct LightPrePassResult
{
    half4 Normal             : SV_Target0;
    half4 Diffuse            : SV_TARGET1;
    half4 MetallicSmoothness : SV_TARGET2;
    half4 CollisionLayer     : SV_TARGET3;
};

struct BRDF
{
    float3 diffuse;
    float3 specular;
    float roughness;
};

struct Surface
{
    float3 normal;
    float3 viewDirection;
    float3 color;
    float alpha;
    float metallic;
    float smoothness;
};

struct PointLight
{
    float3 color;
    float3 direction;
};

#define MIN_REFLECTIVITY 0.04

float OneMinusReflectivity(float metallic)
{
    float range = 1.0 - MIN_REFLECTIVITY;
    return range - metallic * range;
}

BRDF GetBRDF(Surface surface)
{
    BRDF brdf;
    float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

    brdf.diffuse = surface.color * oneMinusReflectivity;
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
    brdf.roughness = PerceptualRoughnessToRoughness(1 - surface.smoothness);
    return brdf;
}

float Square(float x) { return x * x; }

float SpecularStrength(Surface surface, BRDF brdf, PointLight light)
{
    float3 h = normalize(light.direction - surface.viewDirection);
    float nh2 = Square(saturate(dot(surface.normal, h)));
    float lh2 = Square(saturate(dot(light.direction, h)));
    float r2 = Square(brdf.roughness);
    float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
    float normalization = brdf.roughness * 4.0 + 2.0;
    return r2 / (d2 * max(0.1, lh2) * normalization);
}

float MinSpecularStrength(Surface surface, BRDF brdf, PointLight light)
{
    float3 h = normalize(light.direction - surface.normal);
    float nh2 = Square(saturate(dot(surface.normal, h)));
    float lh2 = Square(saturate(dot(light.direction, h)));
    float r2 = Square(brdf.roughness);
    float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
    float normalization = brdf.roughness * 4.0 + 2.0;
    return r2 / (d2 * max(0.1, lh2) * normalization);
}

float3 DirectBRDF(Surface surface, BRDF brdf, PointLight light)
{
    return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}

float3 IncomingLight(Surface surface, PointLight light)
{
    return saturate(dot(surface.normal, light.direction)) * light.color;
}

half4 ApplyNormalsLighting(float3 positionWS, half4 lightColor, float2 lightPosition, float lightZDistance, half3 normalUnpacked)
{
    half3 dirToLight;
    dirToLight.xy = lightPosition.xy - positionWS.xy;
    dirToLight.z =  lightZDistance;
    dirToLight = normalize(dirToLight);
    lightColor.rgb *= saturate(dot(dirToLight, normalUnpacked));
    return lightColor;
}

float3 GetLightColor(Surface surface, BRDF brdf, PointLight light)
{
    return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

float3 GetLightMinSpecularity(Surface surface, BRDF brdf, PointLight light)
{
    return IncomingLight(surface, light) * (MinSpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse);
}

Surface GetSurface(float3 positionWS, float3 normal, float4 diffuse, float metallic, float smoothness)
{
    Surface surface;
    surface.normal = normal;
    float3 viewDirection = positionWS - _WorldSpaceCameraPos;
    surface.viewDirection = normalize(viewDirection);
    surface.color = diffuse.rgb;
    surface.alpha = diffuse.a;
    surface.metallic = metallic;
    surface.smoothness = smoothness;
    return surface;
}

Surface GetSurface(float3 viewDirection, float3 normal, float4 diffuse, float4 metallicSmoothness)
{
    Surface surface;
    surface.normal = normal;
    surface.viewDirection = viewDirection;
    surface.color = diffuse.rgb;
    surface.alpha = diffuse.a;
    surface.metallic = metallicSmoothness.r;
    surface.smoothness = metallicSmoothness.b;
    return surface;
}

float4 GetLighting(float3 positionWS, float2 lightPosition,
                   float lightZDistance, float4 lightColor, float isRealtimeLights,
                   float3 normal, float4 diffuse, float4 metallicSmoothness)
{
    float isBlank = isRealtimeLights && diffuse.rgb == float3(0, 0, 0);
    diffuse.rgb = diffuse.rgb * (1 - isBlank) + float3(.5, .5, .5) * isBlank;
    Surface surface = GetSurface(positionWS.xyz, normal, diffuse, metallicSmoothness.r, metallicSmoothness.g);
    BRDF brdf = GetBRDF(surface);
    PointLight light;
    light.color = lightColor.rgb;
    light.direction.xy = lightPosition.xy - positionWS.xy;
    light.direction.z = lightZDistance;
    light.direction = normalize(light.direction);
    lightColor.rgb = GetLightColor(surface, brdf, light);
    return lightColor;
}

float4 ComputeForwardLight(float3 positionWS, Surface surface, BRDF brdf,
                           float2 lightPosition, float lightZDistance, float4 lightColor)
{
    PointLight light;
    light.color = lightColor.rgb;
    light.direction.xy = lightPosition.xy - positionWS.xy;
    light.direction.z = lightZDistance;
    light.direction = normalize(light.direction);
    lightColor.rgb = GetLightColor(surface, brdf, light);
    return lightColor;
}

float4 GetLightingConstViewZ(float3 positionWS, float2 lightPosition,
                             float lightZDistance, float4 lightColor, float isRealtimeLights,
                             float3 normal, float4 diffuse, float4 metallicSmoothness, float viewZ)
{
    positionWS.z = viewZ + _WorldSpaceCameraPos.z;
    return GetLighting(positionWS, lightPosition, lightZDistance, lightColor, isRealtimeLights,
                       normal, diffuse, metallicSmoothness);
}

float2 SigmaSquared(float a, float x, float y)
{
    float negB = x * x + y * y + 1;
    float desc = sqrt(negB * negB - 4 * a * a * x * x);
    float div = 1.0 / (2 * a * a);
    return float2((negB + desc) * div, (negB - desc) * div);
}

float Sigma(float a, float x, float y)
{
    float2 sqr = SigmaSquared(a, x, y);
    return sqrt(max(sqr.x, sqr.y));
}

float acosh(float x)
{
    return log(x + sqrt(x * x - 1.0));
}

float2 EllipseThetaR(float a, float x, float y)
{
    float sigma = Sigma(a, x, y);
    float r = acosh(sigma);
    float tau = x / (a * sigma);
    float theta = acos(tau);
    return float2(theta, r);
}

float2 EllipseCoords(float2 uv, float2 scale, float xOffset, float a, float thetaScale, float scrollSpeed)
{
    uv *= 2;
    uv -= 1;
    uv.x += xOffset;
    uv.x *= scale.x;
    uv.x -= (scale.x - 1);
    uv.y *= scale.y;

    float2 thetaR = EllipseThetaR(a, uv.x, uv.y);
    float INV_PI_OVER_2 = 0.63661977236;
    float normTheta = abs(thetaR.x) * INV_PI_OVER_2;
    normTheta -= (_Time.y * scrollSpeed * thetaScale);
    return float2(normTheta, thetaR.y);
}

#define DEFINE_LIGHT_PREPASS_TEXTURES() \
    TEXTURE2D(_NormalRenderTex); SAMPLER(sampler_NormalRenderTex); float4 _NormalRenderTex_TexelSize; \
    TEXTURE2D(_DiffuseRenderTex); SAMPLER(sampler_DiffuseRenderTex); float4 _DiffuseRenderTex_TexelSize; \
    TEXTURE2D(_MetallicSmoothnessRenderTex); SAMPLER(sampler_MetallicSmoothnessRenderTex); float4 _MetallicSmoothnessRenderTex_TexelSize; \
    float _RealtimeLightsPass;

#define GET_POINT_LIGHT_COLOR(screenUV, positionWS, lightPosition, lightZDistance, lightColor) \
    GetLightingConstViewZ(positionWS.xyz, lightPosition, lightZDistance, lightColor, _RealtimeLightsPass, \
                UnpackNormal(SAMPLE_TEXTURE2D(_NormalRenderTex, sampler_NormalRenderTex, screenUV)), \
                SAMPLE_TEXTURE2D(_DiffuseRenderTex, sampler_DiffuseRenderTex, screenUV), \
                SAMPLE_TEXTURE2D(_MetallicSmoothnessRenderTex, sampler_MetallicSmoothnessRenderTex, screenUV), -5)

#define DEFINE_FORWARD_LIGHT(idx) \
    float _LightIntensity##idx; float4 _LightColor##idx; float2 _LightPosition##idx; float _LightZDistance##idx;

#define DEFINE_FORWARD_LIGHTS() \
    DEFINE_FORWARD_LIGHT(0) DEFINE_FORWARD_LIGHT(1) DEFINE_FORWARD_LIGHT(2) DEFINE_FORWARD_LIGHT(3)

#define DEFINE_LIGHT_ARG(idx) \
    float LightIntensity##idx, float4 LightColor##idx, float2 LightPosition##idx, float LightZDistance##idx

#define COMPUTE_FORWARD_LIGHT(idx) ComputeForwardLight(positionWS, surface, brdf, \
    LightPosition##idx, LightZDistance##idx, LightIntensity##idx * LightColor##idx)

float4 ComputeForwardLights(float3 positionWS, float3 normal, float4 diffuse, float metallic, float smoothness,
    DEFINE_LIGHT_ARG(0), DEFINE_LIGHT_ARG(1), DEFINE_LIGHT_ARG(2), DEFINE_LIGHT_ARG(3))
{
    Surface surface = GetSurface(positionWS, normal, diffuse, metallic, smoothness);
    BRDF brdf = GetBRDF(surface);
    return COMPUTE_FORWARD_LIGHT(0) + COMPUTE_FORWARD_LIGHT(1) + COMPUTE_FORWARD_LIGHT(2) + COMPUTE_FORWARD_LIGHT(3);
}

#define LIGHT_ARG(idx) \
    _LightIntensity##idx, _LightColor##idx, _LightPosition##idx, _LightZDistance##idx

#define COMPUTE_FORWARD_LIGHTS(positionWS, normal, diffuse, metallic, smoothness) \
    ComputeForwardLights(positionWS, normal, diffuse, metallic, smoothness, \
        LIGHT_ARG(0), LIGHT_ARG(1), LIGHT_ARG(2), LIGHT_ARG(3))

#define NORMALS_LIGHTING_COORDS(TEXCOORDA, TEXCOORDB) \
    half4   positionWS : TEXCOORDA;\
    half2   screenUV   : TEXCOORDB;

#define TRANSFER_NORMALS_LIGHTING(output, worldSpacePos) \
    output.screenUV = ComputeNormalizedDeviceCoordinates(output.positionCS.xyz / output.positionCS.w); \
    output.positionWS = worldSpacePos;

//#define APPLY_NORMALS_LIGHTING(input, lightColor, lightPosition, lightZDistance)\
//    half4 normal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.screenUV);\
//    half3 normalUnpacked = UnpackNormalRGBNoScale(normal);\
//    half3 planeNormal = -GetViewForwardDir();\
//    half3 projLightPos = lightPosition.xyz - (dot(lightPosition.xyz - input.positionWS.xyz, planeNormal) - lightZDistance) * planeNormal;\
//    half3 dirToLight = normalize(projLightPos - input.positionWS.xyz);\
//    lightColor = lightColor * saturate(dot(dirToLight, normalUnpacked));

#if ENABLE_RAYTRACING
float _RaytracedStageLightMultiplier;
float _RaytracedRealtimeLightMultiplier;
float _RaytracedBaseLightMultiplier;
float _RaytracedParticleLightMultiplier;
float _RaytracedParticleLightScale;
float _RaytracedZDistance;
#endif
