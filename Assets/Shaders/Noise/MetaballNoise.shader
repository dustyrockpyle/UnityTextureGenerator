Shader "MetaballNoise"
{
    Properties
    {
        _ScaleX("ScaleX", Int) = 10
        _ScaleY("ScaleY", Int) = 10
        _Octaves("Octaves", Int) = 1
        _Shift("Shift", Range(0, 50)) = 0
        _TimeShift("TimeShift", Range(0, 50)) = 0
        _Gain("Gain", Range(0, 2)) = .5
        _Lacunarity("Lacunarity", Range(1, 32)) = 1
        _OctaveFactor("OctaveFactor", Range(-1, 1)) = 0
        _Interpolate("Interpolate", Float) = 0
        _Jitter("Jitter", Range(0, 1)) = 1
        _WidthX("WidthX", Range(0, 1)) = .1
        _WidthY("WidthY", Range(0, 1)) = .01
        _Seed("Seed", Range(0, 1000)) = 0
        [Toggle]_Inverse("Inverse", Float) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"

    float _ScaleX;
    float _ScaleY;
    int _Octaves;
    float _Shift;
    float _TimeShift;
    float _Gain;
    float _Lacunarity;
    float _OctaveFactor;
    float _Interpolate;
    float _Jitter;
    float _WidthX;
    float _WidthY;
    float _Seed;
    float _Inverse;
    ENDHLSL

    SubShader
    {
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
            };

            struct Varyings
            {
                float4  positionCS  : SV_POSITION;
                float2	uv          : TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 scale = float2(_ScaleX, _ScaleY);
                float2 pos = i.uv;
                float2 width = float2(_WidthX, _WidthY);
                float value = fbmMetaballs(pos, scale, _Octaves, _Shift, _TimeShift, _Gain,
                                           _Lacunarity, _OctaveFactor, _Jitter, _Interpolate, width, _Seed);
                value = saturate(value);
                value = (1 - value) * _Inverse + (1 - _Inverse) * value;
                return float4(comp3(value), 1);
            }
            ENDHLSL
        }
    }
}
