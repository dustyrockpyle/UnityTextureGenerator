Shader "BatchWarpFbmFog"
{
    Properties
    {
        _DisableExternalLighting("DisableExternalLighting", Float) = 1
        _ScaleX("ScaleX", Int) = 10
        _ScaleY("ScaleY", Int) = 10
        _Octaves("Octaves", Int) = 1
        _Gain("Gain", Range(0, 2)) = .5
        _Lacunarity("Lacunarity", Range(1, 32)) = 1
        _OctaveFactor("OctaveFactor", Range(-1, 1)) = 0
        _Seed("Seed", Range(0, 1000)) = 0
        _Scroll1("Scroll1", Range(0, .25)) = 0
        _Scroll2("Scroll2", Range(0, .25)) = 0
        _Scroll3("Scroll3", Range(-.5, .5)) = 0
        _Scroll4("Scroll4", Range(-.5, .5)) = 0
        _Color1("Color1", Color) = (.101, .619, .666, 1)
        _Color2("Color2", Color) = (.666, .666, .498, 1)
        _Color3("Color3", Color) = (.031, .004, .165, 1)
        _Color4("Color4", Color) = (.666, 1, 1, 1)
        _TileCount("TileCount", Int) = 64
        _AlphaMultiplier("AlphaMultiplier", Range(.25, 20)) = 1

        [Toggle(ENABLE_LIT)] _EnableLit ("Enable Lighting", Float) = 0
        _LightIntensityMultiplier("Light Intensity Multiplier", Float) = 1
    }

    HLSLINCLUDE
    #include "Assets/Shaders/Utils/ShaderHelpers.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"

    #pragma shader_feature ENABLE_LIT

    int _ScaleX;
    int _ScaleY;
    int _Octaves;
    float _Gain;
    float _Lacunarity;
    float _OctaveFactor;
    float _Scroll1;
    float _Scroll2;
    float _Scroll3;
    float _Scroll4;

    float _Seed;

    float3 _Color1;
    float3 _Color2;
    float3 _Color3;
    float3 _Color4;

    float _DisableExternalLighting;
    float _TileCount;
    float _AlphaMultiplier;

    #ifdef ENABLE_LIT
    float _LightIntensityMultiplier;
    #endif

    TEXTURE2D(_StageLightRenderTex);
    SAMPLER(sampler_StageLightRenderTex);

    TEXTURE2D(_RealtimeLightRenderTex);
    SAMPLER(sampler_RealtimeLightRenderTex);

    struct BatchDecalShaderGPUData
    {
        float2 Position;
        float2 Scale;
        float Rotation;
        float Deflection;
        float DistanceToPlayer;
        uint PaletteAndTile;
    };
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
        StructuredBuffer<BatchDecalShaderGPUData> batchDecalShaderDataBuffer;

        int GetPalette(BatchDecalShaderGPUData data)
        {
            return (data.PaletteAndTile >> 0x10) & 0xFF;
        }

        int GetTile(BatchDecalShaderGPUData data)
        {
            return data.PaletteAndTile & 0xFF;
        }
    #else
    UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_DEFINE_INSTANCED_PROP(float, _Tile)
        UNITY_DEFINE_INSTANCED_PROP(float, _Palette)
    UNITY_INSTANCING_BUFFER_END(Props)
    #endif

    int _Offset;
    float _ZOffset;
    float3 _TestScale;

    void setup()
    {
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
        BatchDecalShaderGPUData shaderData = batchDecalShaderDataBuffer[_Offset + unity_InstanceID];
        float2 position = shaderData.Position;
        float2 scale = shaderData.Scale;
        float2 rotation = RotationFromAngle(shaderData.Rotation);

        unity_ObjectToWorld = float4x4(
          rotation.x * scale.x, -rotation.y * scale.y,          0, position.x,
          rotation.y * scale.x,  rotation.x * scale.y,          0, position.y,
                             0,                     0,          1,   _ZOffset,
                             0,                     0,          0,          1
        );
    #endif
    }

    struct Attributes
    {
        float3 positionOS   : POSITION;
        float2  uv           : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        half2  lightingUV  : TEXCOORD2;
        NORMALS_LIGHTING_COORDS(TEXCOORD4, TEXCOORD5)
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings vert(Attributes input)
    {
        Varyings output = (Varyings)0;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);

        #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
        BatchDecalShaderGPUData shaderData = batchDecalShaderDataBuffer[_Offset + unity_InstanceID];
        float2 scale = shaderData.Scale;
        #else
        float2 scale = _TestScale;
        #endif

        output.uv = input.uv;
        float4 positionWS;
        positionWS.xyz = TransformObjectToWorld(input.positionOS);
        positionWS.w = 1;
        output.positionCS = TransformWorldToHClip(positionWS.xyz);
        output.lightingUV = ComputeLightingUV(output.positionCS).xy;

        TRANSFER_NORMALS_LIGHTING(output, positionWS);

        return output;
    }

    float fbm(float2 st)
    {
        float2 scale = float2(_ScaleX, _ScaleY);
        return fbm(st, scale, _Octaves, .5 + _SinTime.z * _Scroll1, _Time.x * _Scroll2, _Gain, _Lacunarity, _OctaveFactor, _Seed);
    }

    float4 fbmFog(Varyings i, float2 offset)
    {
        float4 result;
        result.a = 1;
        float2 scale = float2(_ScaleX, _ScaleY);
        float2 pos = i.uv + offset;
        float2 q;
        q.x = fbm(pos);
        q.y = fbm(pos + float2(-.52, .88));
        float2 r;
        r.x = fbm(pos + .352 * q + float2(1.7, 9.2) + _Scroll3 * _Time.x * 5 / _ScaleX);
        r.y = fbm(pos + .064 * q + float2(.21, .58) + _Scroll4 * _Time.x * 5 / _ScaleX);
        float f = fbm(pos + r);
        float3 color = lerp(_Color1, _Color2, saturate(f * f * 4));
        color = lerp(color, _Color3, saturate(length(q)));
        color = lerp(color, _Color4, saturate(r.x));
        color *= (f * f * f + .6 * f * f + .56 * f);
        result.rgb = color;
        result.a = f * f * f;
        result.a *= .25;
        return result;
    }

    float4 frag(Varyings i) : SV_Target
    {
        float4 fog1 = fbmFog(i, float2(0, 0));
        float lerpF = sin(_Time.x) * .5 + .5;
        float off2 = lerp(.33, .40, lerpF);
        float4 fog2 = fbmFog(i, float2(off2, off2));
        float4 color = lerp(fog1, fog2, lerp(.25, .75, lerpF));
        float4 uvs = float4(i.uv.x, i.uv.y, i.uv.x, i.uv.y);
        float4 bounds1 = float4(0, 0, 1, 1);
        float4 bounds2 = float4(.1, .1, .9, .9);
        float4 steps = smoothstep(uvs, bounds1, bounds2);
        float borderAlpha = steps.x * steps.y * steps.z * steps.w;
        color.a *= _AlphaMultiplier * borderAlpha;

        #if ENABLE_LIT
        float4 light = SAMPLE_TEXTURE2D(_RealtimeLightRenderTex, sampler_RealtimeLightRenderTex, i.lightingUV);
        color.rgb += color.a * color.rgb * light.rgb * _LightIntensityMultiplier;
        #endif

        return color;
    }

    ENDHLSL

    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Blend SrcAlpha One
        Cull Off
        ZTest LEqual
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            ENDHLSL
        }
    }
}
