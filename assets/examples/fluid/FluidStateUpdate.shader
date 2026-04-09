Shader "SkillExamples/URP/Fluid/FluidStateUpdate"
{
    Properties
    {
        _PreviousState("Previous State", 2D) = "black" {}
        _DeltaTime("Delta Time", Float) = 0.016
        _Dissipation("Dissipation", Range(0.0, 1.0)) = 0.025
        _BrushPosition("Brush Position", Vector) = (0.5, 0.5, 0.0, 0.0)
        _BrushRadius("Brush Radius", Float) = 0.1
        _BrushStrength("Brush Strength", Float) = 1.0
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
            Name "FluidUpdate"
            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _DeltaTime;
                float _Dissipation;
                float4 _BrushPosition;
                float _BrushRadius;
                float _BrushStrength;
            CBUFFER_END

            TEXTURE2D(_PreviousState);
            SAMPLER(sampler_PreviousState);

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

            half4 Frag(Varyings input) : SV_Target
            {
                half previous = SAMPLE_TEXTURE2D(_PreviousState, sampler_PreviousState, input.uv).r;
                half brushMask = saturate(1.0h - distance(input.uv, _BrushPosition.xy) / max(_BrushRadius, 1e-4));
                half injected = brushMask * _BrushStrength * _DeltaTime;
                half value = max(previous * (1.0h - _Dissipation * _DeltaTime), injected);
                return half4(value, value * 0.5h, value * value, 1.0h);
            }
            ENDHLSL
        }
    }
}
