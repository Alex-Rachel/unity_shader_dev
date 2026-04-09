Shader "SkillExamples/URP/Lighting/ForwardLitExample"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
        _AmbientColor("Ambient Color", Color) = (0.10, 0.10, 0.12, 1)
        _Smoothness("Smoothness", Range(0, 1)) = 0.35
        _RimColor("Rim Color", Color) = (0.35, 0.65, 1.0, 1.0)
        _RimPower("Rim Power", Range(0.5, 8.0)) = 3.0
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5

            #pragma multi_compile_fragment _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _AmbientColor;
                float4 _RimColor;
                float _Smoothness;
                float _RimPower;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.shadowCoord = GetShadowCoord(positionInputs);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 albedoSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 albedo = albedoSample.rgb * _BaseColor.rgb;
                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);

                Light mainLight = GetMainLight(input.shadowCoord);
                half ndotl = saturate(dot(normalWS, mainLight.direction));
                half3 diffuse = albedo * mainLight.color * (ndotl * mainLight.shadowAttenuation);

                half3 halfVector = SafeNormalize(mainLight.direction + viewDirWS);
                half specular = pow(saturate(dot(normalWS, halfVector)), lerp(8.0h, 128.0h, _Smoothness));

                half rim = pow(1.0h - saturate(dot(normalWS, viewDirWS)), _RimPower);
                half3 ambient = albedo * _AmbientColor.rgb;
                half3 color = ambient + diffuse + specular * mainLight.color + _RimColor.rgb * rim;
                return half4(color, albedoSample.a * _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
