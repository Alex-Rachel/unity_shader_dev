Shader "SkillExamples/URP/Fluid/FluidPreview"
{
    Properties
    {
        _StateTex("State Texture", 2D) = "black" {}
        _Tint("Tint", Color) = (0.18, 0.65, 1.0, 1.0)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _StateTex_ST;
                float4 _Tint;
            CBUFFER_END

            TEXTURE2D(_StateTex);
            SAMPLER(sampler_StateTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _StateTex);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half3 state = SAMPLE_TEXTURE2D(_StateTex, sampler_StateTex, input.uv).rgb;
                return half4(state * _Tint.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}
