Shader "SkillExamples/URP/PostProcessing/ToneMapPass"
{
    Properties
    {
        _SourceTexture("Source Texture", 2D) = "white" {}
        _Exposure("Exposure", Range(0.0, 5.0)) = 1.0
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
            Name "ToneMap"
            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Exposure;
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
                output.uv = float2((input.vertexID << 1) & 2, input.vertexID & 2);
                output.positionCS = float4(output.uv * 2.0 - 1.0, 0.0, 1.0);
                output.positionCS.y *= -1.0;
                return output;
            }

            float3 Reinhard(float3 color)
            {
                return color / (1.0 + color);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 source = SAMPLE_TEXTURE2D(_SourceTexture, sampler_SourceTexture, input.uv).rgb;
                float3 mapped = Reinhard(source * _Exposure);
                return half4(mapped, 1.0);
            }
            ENDHLSL
        }
    }
}
