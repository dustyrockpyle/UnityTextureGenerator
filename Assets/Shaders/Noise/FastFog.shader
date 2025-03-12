Shader "FastFog"
{
    Properties
    {
        _ScaleX("ScaleX", Int) = 10
        _ScaleY("ScaleY", Int) = 10
        _Octaves("Octaves", Int) = 1
        _Gain("Gain", Range(0, 2)) = .5
        _Lacunarity("Lacunarity", Range(1, 32)) = 1
        _OctaveFactor("OctaveFactor", Range(-1, 1)) = 0
        _Seed("Seed", Range(0, 1000)) = 0
        _RadialFactor("RadialFactor", Range(0, 100)) = 0
        _RadialDistance("RadialDistance", Range(0, 1)) = 0
        _ValueThreshold("ValueThreshold", Range(0, 3)) = 0
        _Scroll1("Scroll1", Range(0, .25)) = 0
        _Scroll2("Scroll2", Range(0, .25)) = 0
        _Slopeness("Slopeness", Range(0, 1)) = 0

        _ScaleX2("ScaleX2", Int) = 10
        _ScaleY2("ScaleY2", Int) = 10
        _Octaves2("Octaves2", Int) = 1
        _Gain2("Gain2", Range(0, 2)) = .5
        _Lacunarity2("Lacunarity2", Range(1, 32)) = 1
        _OctaveFactor2("OctaveFactor2", Range(-1, 1)) = 0
        _Seed2("Seed2", Range(0, 1000)) = 0
        _ValueThreshold2("ValueThreshold2", Range(0, 3)) = 0
        _Scroll3("Scroll3", Range(0, .25)) = 0
        _Scroll4("Scroll4", Range(0, .25)) = 0
        _Slopeness2("Slopeness2", Range(0, 1)) = 0

        _MetaScaleX("MetaScaleX", Int) = 10
        _MetaScaleY("MetaScaleY", Int) = 10
        _MetaOctaves("MetaOctaves", Int) = 1
        _MetaGain("MetaGain", Range(0, 2)) = .5
        _MetaLacunarity("MetaLacunarity", Range(1, 32)) = 1
        _MetaOctaveFactor("MetaOctaveFactor", Range(-1, 1)) = 0
        _MetaInterpolate("MetaInterpolate", Range(-1, 1)) = 0
        _MetaJitter("MetaJitter", Range(0, 1)) = 1
        _MetaWidthX("MetaWidthX", Range(0, 1)) = .1
        _MetaWidthY("MetaWidthY", Range(0, 1)) = .01
        _MetaSeed("MetaSeed", Range(0, 1000)) = 0
        _MetaScroll1("MetaScroll1", Range(0, .25)) = 0
        _MetaScroll2("MetaScroll2", Range(0, .25)) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"

    int _ScaleX;
    int _ScaleY;
    int _Octaves;
    float _Gain;
    float _Lacunarity;
    float _OctaveFactor;
    float _Scroll1;
    float _Scroll2;
    float _Slopeness;

    float _Seed;
    float _RadialFactor;
    float _RadialDistance;
    float _ValueThreshold;

    float _ScaleX2;
    float _ScaleY2;
    float _Octaves2;
    float _Gain2;
    float _Lacunarity2;
    float _OctaveFactor2;
    float _Seed2;
    float _ValueThreshold2;
    float _Scroll3;
    float _Scroll4;
    float _Slopeness2;

    int _MetaOctaves;
    int _MetaScaleX;
    int _MetaScaleY;
    float _MetaGain;
    float _MetaLacunarity;
    float _MetaOctaveFactor;
    float _MetaInterpolate;
    float _MetaJitter;
    float _MetaWidthX;
    float _MetaWidthY;
    float _MetaSeed;
    float _MetaScroll1;
    float _MetaScroll2;
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

            float fbm(float2 st)
            {
                float2 scale = float2(_ScaleX2, _ScaleY2);
                return fbm(st, scale, 4, .5, _Time.x * .07, .25, 2, -1, 0);
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 scale = float2(_ScaleX, _ScaleY);
                float2 pos = i.uv;
                //float value2 = fbm(pos, int2(_ScaleX2, _ScaleY2), _Octaves2, _Time.y * _Scroll3, _Time.y * _Scroll4, _Gain2,
                //                   _Lacunarity2, _OctaveFactor2, _Seed2);
                //float value2 = fbmdPerlin(pos, int2(_ScaleX2, _ScaleY2), _Octaves2, _Time.y * _Scroll3, _Time.y * _Scroll4, _Gain2,
                //                   _Lacunarity2, _Slopeness2, _OctaveFactor2, false, _Seed2);
                //float value2 = fbmPerlin(pos, int2(_ScaleX2, _ScaleY2), _Octaves2, _Time.y * _Scroll3, _Time.y * _Scroll4, _Gain2,
                //                   _Lacunarity2, 4, 1.0, 0.0, _OctaveFactor2, _Seed2);
                float2 q, r;
                float value2 = fbmWarp(pos, int2(_ScaleX2, _ScaleY2), float2(1, 1), _Octaves2, comp4(_Time.y * _Scroll3), _Time.y * _Scroll4, _Gain2,
                                   float2(_Lacunarity2, _Lacunarity2), _Slopeness2, _OctaveFactor2, false, _Seed2, q, r);
                float value = fbm(pos + lerp(-.025, .025, value2) % 1, scale, _Octaves, _Time.x * _Scroll1, _Time.z * _Scroll2, _Gain,
                                  _Lacunarity, _OctaveFactor, _Seed);
                float2 width = float2(_MetaWidthX, _MetaWidthY);
                float metaNoise = fbmMetaballs(pos, float2(_MetaScaleX, _MetaScaleY), _MetaOctaves, _Time.w * _MetaScroll1, _Time.z * _MetaScroll2, _MetaGain,
                   _MetaLacunarity, _MetaOctaveFactor, _MetaJitter, _MetaInterpolate, width, _MetaSeed);
                //metaNoise = 1 - saturate(metaNoise);
                value = saturate(value);
                value = smoothstep(0, _ValueThreshold, value);
                value2 = saturate(value2);
                value2 = smoothstep(0, _ValueThreshold2, value2);
                //return float4(comp3(value), 1);
                //return float4(comp3(value2), 1);
                //return float4(comp3((1 - metaNoise) * value), 1);
                //return float4(comp3(value2 * value), 1);
                return float4(comp3(lerp(value, value2, metaNoise)), 1);
            }
            ENDHLSL
        }
    }
}
