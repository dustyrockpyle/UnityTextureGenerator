Shader "FlipbookCircleAlpha"
{
    Properties
    {
        [NoScaleOffset]_MainTex("_MainTex", 2D) = "white" {}
        _Width("Width", Range(0, 1)) = .1
        _AlphaWidth("AlphaWidth", Range(0, .1)) = .1
        _Rows("Rows", Int) = 2
        _Cols("Cols", Int) = 5
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Assets/Shaders/Noise/NoiseHelpers.hlsl"
    #include "Assets/Shaders/Utils/ShaderHelpers.hlsl"

    float _Width;
    float _AlphaWidth;
    float _Rows;
    float _Cols;

    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;

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
                float4 result = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float colSize = 1.0 / _Cols;
                float rowSize = 1.0 / _Rows;
                int col = floor(i.uv.x / colSize);
                int row = floor(i.uv.y / rowSize);
                float2 uvOffset = float2(col * colSize, row * rowSize);
                float2 uvAdj = (i.uv - uvOffset) / float2(colSize, rowSize);
                float2 uvRescale = uvAdj * 2 - 1;
                float xySqr = uvRescale.x * uvRescale.x + uvRescale.y * uvRescale.y;
                float widthSqr = _Width * _Width;
                float alphaSqr = (_Width - _AlphaWidth) * (_Width - _AlphaWidth);
                float alpha = invLerpSat(widthSqr, alphaSqr, xySqr);
                result.a = alpha;
                return result;
            }
            ENDHLSL
        }
    }
}
