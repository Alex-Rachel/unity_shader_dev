Shader "SkillTemplates/URP/ForwardLit"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0.0, 2.0)) = 1.0
        _AmbientColor("Ambient Color", Color) = (0.12,0.12,0.12,1)
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.25
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
                float4 _NormalMap_ST;
                float4 _AmbientColor;
                float _NormalScale;
                float _Smoothness;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float4 shadowCoord : TEXCOORD4;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = float4(normalInputs.tangentWS, input.tangentOS.w);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.shadowCoord = GetShadowCoord(positionInputs);
                return output;
            }

            half3 SampleNormalTS(float2 uv)
            {
                half4 packed = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                return UnpackNormalScale(packed, _NormalScale);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 albedoSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 albedo = albedoSample.rgb * _BaseColor.rgb;

                float sgn = input.tangentWS.w;
                float3 bitangentWS = sgn * cross(input.normalWS, input.tangentWS.xyz);
                float3x3 tangentToWorld = float3x3(input.tangentWS.xyz, bitangentWS, input.normalWS);
                half3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(SampleNormalTS(input.uv), tangentToWorld));

                Light mainLight = GetMainLight(input.shadowCoord);
                half ndotl = saturate(dot(normalWS, mainLight.direction));
                half3 diffuse = albedo * mainLight.color * (ndotl * mainLight.shadowAttenuation);

                half3 viewDirWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);
                half3 halfVector = SafeNormalize(mainLight.direction + viewDirWS);
                half specular = pow(saturate(dot(normalWS, halfVector)), lerp(8.0h, 128.0h, _Smoothness));

                half3 ambient = albedo * _AmbientColor.rgb;
                half3 color = ambient + diffuse + specular * mainLight.color;
                return half4(color, albedoSample.a * _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
