Shader "WarpFbmFog"
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
        _Scroll1("Scroll1", Range(0, .25)) = 0
        _Scroll2("Scroll2", Range(0, .25)) = 0
        _Scroll3("Scroll3", Range(-.5, .5)) = 0
        _Scroll4("Scroll4", Range(-.5, .5)) = 0
        _Color1("Color1", Color) = (.101, .619, .666, 1)
        _Color2("Color2", Color) = (.666, .666, .498, 1)
        _Color3("Color3", Color) = (.031, .004, .165, 1)
        _Color4("Color4", Color) = (.666, 1, 1, 1)
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
    float _Scroll3;
    float _Scroll4;

    float _Seed;

    float3 _Color1;
    float3 _Color2;
    float3 _Color3;
    float3 _Color4;

    ENDHLSL

    SubShader
    {
        Blend SrcAlpha Zero
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

            float fbm(float2 st)
            {
                float2 scale = float2(_ScaleX, _ScaleY);
                return fbm(st, scale, _Octaves, .5 + _SinTime.z * _Scroll1, _Time.x * _Scroll2, _Gain, _Lacunarity, _OctaveFactor, _Seed);
            }

            float4 frag1(Varyings i, float2 offset)
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

                // This is an attempt to separate the channels - and each channel could be used as a fog "layer"
                // Haven't figured out a good way to combine it yet; just combining with different colors doesn't
                // seem great. Would be better to overlay them with another set of "overlapping" noise blobs that
                // could work as fog clouds.
                //color = saturate(float3(f * f * 2,  length(q), r.x) * (f * f * f + .6 * f * f + .56 * f));
                //result.rgb = saturate(abs(color.r - color.g + color.b));
                //result.rgb = saturate(abs(color.b - color.g));
                //result.rgb = saturate(abs(color.r));
                //result.rgb = saturate(abs(color.b - color.g * _SinTime.z * .25));

                result.rgb = color;
                result.a = f * f * f;
                return result;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float4 c1 = frag1(i, float2(0, 0));
                float lerpF = sin(_Time.x) * .5 + .5;
                float off2 = lerp(.33, .40, lerpF);
                float4 c2 = frag1(i, float2(off2, off2));
                return lerp(c1, c2, lerp(.25, .75, lerpF));
            }
            ENDHLSL
        }
    }
}
