Shader "SkillTemplates/URP/FullscreenEffect"
{
    Properties
    {
        _SourceTexture("Source Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1,1)
        _Intensity("Intensity", Range(0.0, 2.0)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Overlay"
        }

        Pass
        {
            Name "Fullscreen"
            ZWrite Off
            ZTest Always
            Cull Off
            Blend One Zero

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _Tint;
                float _Intensity;
            CBUFFER_END

            TEXTURE2D(_SourceTexture);
            SAMPLER(sampler_SourceTexture);

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                // Use URP Core macros for platform-correct NDC and UV.
                // These handle UNITY_UV_STARTS_AT_TOP and Blitter compatibility automatically.
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 source = SAMPLE_TEXTURE2D(_SourceTexture, sampler_SourceTexture, input.uv);
                half3 result = source.rgb * _Tint.rgb * _Intensity;
                return half4(result, source.a);
            }
            ENDHLSL
        }
    }
}
