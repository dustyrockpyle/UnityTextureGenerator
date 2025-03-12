Shader "CrackNoise"
{

    Properties
    {
        _ScaleX("ScaleX", Int) = 10
        _ScaleY("ScaleY", Int) = 10
        _Jitter("Jitter", Range(0, 1)) = 1
        _Width("Width", Range(0, 1)) = .1
        _Smoothness("Smoothness", Range(0, 1)) = 0
        _Warp("Warp", Range(0, 1)) = 0
        _WarpScale("WarpScale", Float) = 2
        _WarpSmudge("WarpSmudge", Float) = 0
        _Seed("Seed", Float) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"

    float _ScaleX;
    float _ScaleY;
    float _Jitter;
    float _Width;
    float _Smoothness;
    float _Warp;
    float _WarpScale;
    float _WarpSmudge;
    float _Seed;
    ENDHLSL

    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZTest Always
        ZWrite Off

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
                float crack = cracks(pos, scale, _Jitter, _Width, _Smoothness, _Warp,
                                     _WarpScale, _WarpSmudge, _Seed);
                return float4(comp3(crack), 1);
            }
            ENDHLSL
        }
    }
}
