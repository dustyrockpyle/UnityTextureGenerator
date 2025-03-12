Shader "CurlWarpWallTexture"
{
    Properties
    {
        _ScaleX("ScaleX", Int) = 10
        _ScaleY("ScaleY", Int) = 10
        _Curl("Curl", Range(0, 1)) = .5
        _FactorQ("FactorQ", Range(-1, 1)) = 1
        _FactorR("FactorR", Range(-1, 1)) = 1
        _QRSeeds("PQSeeds", Vector) = (9, 12, 15, 18)
        _Seed("Seed", Range(0, 100)) = 0
        _Color0("Color0", Color) = (1, 0, 0, 1)
        _Color1("Color1", Color) = (0, 1, 0, 1)
        _Color2("Color2", Color) = (0, 0, 1, 1)
        _Color3("Color3", Color) = (1, 1, 0, 1)
        _Color4("Color4", Color) = (0, 1, 1, 1)
        _Color5("Color5", Color) = (1, 0, 1, 1)
        _Color6("Color6", Color) = (1, 1, 1, 1)
        _Color7("Color7", Color) = (0, 0, 0, 1)

        [Toggle(ENABLE_NOISE_TEX)] _EnableNoiseTex ("EnableNoiseTex", Float) = 0
        [NoScaleOffset] _NoiseTex("NoiseTex", 2D) = "white" {}
        _NoiseScaleX("NoiseScaleX", Int) = 10
        _NoiseScaleY("NoiseScaleY", Int) = 10
        _NoiseFactorQ("NoiseFactorQ", Range(-1, 1)) = .2
        _NoiseFactorR("NoiseFactorR", Range(-1, 1)) = .2
        _NoiseOctaves("NoiseOctaves", Range(1, 10)) = 3
        _NoiseShifts("NoiseShifts", Vector) = (0, 0, 0, 0)
        _NoiseGain("NoiseGain", Range(0, 2)) = .5
        _NoiseLacunarity("NoiseLacunarity", Range(0, 10)) = 2
        _NoiseSlopeness("NoiseSlopeness", Range(0, 1)) = .5
        _NoiseOctaveFactor("OctaveFactor", Range(-1, 1)) = 0
        _NoiseSeed("NoiseSeed", Range(0, 100)) = 0
        _NoiseLowerBounds("NoiseLowerBounds", Range(0, 1)) = 0
        _NoiseUpperBounds("NoiseUpperBounds", Range(0, 1)) = 1

        _NoiseWeightW("NoiseWeightW", Range(0, 1)) = .5

        _CurlWarpHeightWeight("CurlWarpHeightWeight", Range(0, 1)) = 1
        _NoiseHeightWeight("NoiseHeightWeight", Range(0, 2)) = .25
        _NosieHeightOffset("NosieHeightOffset", Range(0, 1)) = 0

        [Toggle] _OutputHeight("OutputHeight", Float) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"
    #include "Assets/Shaders/Utils/ShaderHelpers.hlsl"

    #pragma shader_feature ENABLE_NOISE_TEX

    float _ScaleX;
    float _ScaleY;
    float _Curl;
    float4 _QRSeeds;
    float _Seed;
    float _FactorQ;
    float _FactorR;

    float4 _Color0;
    float4 _Color1;
    float4 _Color2;
    float4 _Color3;
    float4 _Color4;
    float4 _Color5;
    float4 _Color6;
    float4 _Color7;

    TEXTURE2D(_NoiseTex);
    SAMPLER(sampler_NoiseTex);

    int _NoiseScaleX;
    int _NoiseScaleY;
    float _NoiseFactorQ;
    float _NoiseFactorR;
    int _NoiseOctaves;
    float4 _NoiseShifts;
    float _NoiseGain;
    int _NoiseLacunarity;
    float _NoiseSlopeness;
    float _NoiseOctaveFactor;
    int _NoiseSeed;

    float _NoiseWarp;
    float _NoiseLowerBounds;
    float _NoiseUpperBounds;
    float _NoiseWeightW;

    float _CurlWarpHeightWeight;
    float _NoiseHeightWeight;
    float _NosieHeightOffset;

    float _OutputHeight;
    ENDHLSL

    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZTest LEqual
        ZWrite On

        Pass
        {
            Tags
            {
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            struct Attributes
            {
                float3 positionOS   : POSITION;
                float2  uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4  positionCS  : SV_POSITION;
                float2	uv          : TEXCOORD0;
            };

            void barycentric_weights(float u, float v, float w, out float4 weights1, out float4 weights2)
            {
                weights1.x = (1 - u) * (1 - v) * (1 - w);
                weights1.y = u * (1 - v) * (1 - w);
                weights1.z = (1 - u) * v * (1 - w);
                weights1.w = u * v * (1 - w);

                weights2.x = (1 - u) * (1 - v) * w;
                weights2.y = u * (1 - v) * w;
                weights2.z = (1 - u) * v * w;
                weights2.w = u * v * w;
            }

            Varyings vert(Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 scale = float2(_ScaleX, _ScaleY);
                float2 pos = i.uv;
                #ifdef ENABLE_NOISE_TEX
                float overlay = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv).r;
                #else
                float2 nQ, nR;
                float overlay = fbmPerlinWarp(pos, int2(_NoiseScaleX, _NoiseScaleY), float2(_NoiseFactorQ, _NoiseFactorR),
                                        _NoiseOctaves, _NoiseShifts, 4, _NoiseGain, float2(_NoiseLacunarity, _NoiseLacunarity),
                                        _NoiseSlopeness, _NoiseOctaveFactor, false, _NoiseSeed, nQ, nR);
                #endif
                overlay = invLerpSat(_NoiseLowerBounds, _NoiseUpperBounds, overlay);
                float2 q, r = 0;
                float v = curlWarp(pos, scale, float2(_FactorQ, _FactorR), _QRSeeds, _Curl, _Seed, q, r);
                r = r * .5 + .5;
                q = q * .5 + .5;
                float4 w1, w2;
                float w = (1 - _NoiseWeightW) * saturate(q.y - q.x) + _NoiseWeightW * overlay;
                barycentric_weights(r.y, overlay, w, w1, w2);
                float4 color = w1.x * _Color0 + w1.y * _Color1 + w1.z * _Color2 + w1.w * _Color3 +
                    w2.x * _Color4 + w2.y * _Color5 + w2.z * _Color6 + w2.w * _Color7;
                float overlayHeight = overlay * _NoiseHeightWeight - _NosieHeightOffset * _NoiseHeightWeight;
                float4 height = float4(comp3(saturate(r.y * _CurlWarpHeightWeight + overlayHeight)), 1);
                float doHeight = _OutputHeight > 0;
                return (1 - doHeight) * color + doHeight * height;
            }
            ENDHLSL
        }
    }
}
