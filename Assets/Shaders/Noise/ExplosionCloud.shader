Shader "ExplosionCloud"
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
        _Seed("Seed", Range(0, 1000)) = 0
        _RadialFactor("RadialFactor", Range(0, 100)) = 0
        _RadialDistance("RadialDistance", Range(0, 1)) = 0
        _ValueThreshold("ValueThreshold", Range(0, 1)) = 0
        [Toggle]_Inverse("Inverse", Float) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"

    int _ScaleX;
    int _ScaleY;
    int _Octaves;
    float _Shift;
    float _TimeShift;
    float _Gain;
    float _Lacunarity;
    float _OctaveFactor;

    float _Seed;
    float _Inverse;
    float _RadialFactor;
    float _RadialDistance;
    float _ValueThreshold;
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
                float value = fbm(pos, scale, _Octaves, _Shift, _TimeShift, _Gain,
                                  _Lacunarity, _OctaveFactor, _Seed);
                value = saturate(value);
                value = (1 - value) * _Inverse + (1 - _Inverse) * value;
                float xFactor = (i.uv.x - .5) * 2;
                xFactor = 1 - xFactor * xFactor;
                float yFactor = (i.uv.y - .5) * 2;
                yFactor = 1 - yFactor * yFactor;
                float radialFactor = pow(xFactor * yFactor, _RadialFactor);
                float radialMultiplier = 1 - smoothstep(radialFactor - _RadialDistance, radialFactor, value);
                value = radialMultiplier * value;
                value = smoothstep(0, _ValueThreshold, value);
                return float4(comp3(value), 1);
            }
            ENDHLSL
        }
    }
}
