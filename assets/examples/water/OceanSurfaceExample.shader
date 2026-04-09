Shader "SkillExamples/URP/Water/OceanSurfaceExample"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _ShallowColor("Shallow Color", Color) = (0.16, 0.56, 0.62, 1.0)
        _DeepColor("Deep Color", Color) = (0.04, 0.15, 0.24, 1.0)
        _AmbientColor("Ambient Color", Color) = (0.05, 0.09, 0.11, 1.0)
        _WaveAmplitude("Wave Amplitude", Range(0.0, 0.5)) = 0.08
        _WaveFrequency("Wave Frequency", Range(0.1, 8.0)) = 2.2
        _WaveSpeed("Wave Speed", Range(0.0, 4.0)) = 1.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.65
        _FresnelPower("Fresnel Power", Range(1.0, 8.0)) = 4.0
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
                float4 _BaseMap_ST;
                float4 _ShallowColor;
                float4 _DeepColor;
                float4 _AmbientColor;
                float _WaveAmplitude;
                float _WaveFrequency;
                float _WaveSpeed;
                float _Smoothness;
                float _FresnelPower;
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

            float SampleWaveHeight(float2 xz, float time)
            {
                float waveA = sin(xz.x * _WaveFrequency + time * _WaveSpeed);
                float waveB = cos(xz.y * (_WaveFrequency * 0.73) - time * (_WaveSpeed * 1.11));
                return (waveA + waveB) * _WaveAmplitude;
            }

            float3 SampleWaveNormal(float2 xz, float time)
            {
                float epsilon = 0.05;
                float h = SampleWaveHeight(xz, time);
                float hx = SampleWaveHeight(xz + float2(epsilon, 0.0), time);
                float hz = SampleWaveHeight(xz + float2(0.0, epsilon), time);
                return normalize(float3(h - hx, epsilon, h - hz));
            }

            Varyings Vert(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                positionWS.y += SampleWaveHeight(positionWS.xz, _Time.y);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(TransformWorldToObject(positionWS));
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionWS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.shadowCoord = GetShadowCoord(positionInputs);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half3 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;
                half3 waveNormal = SampleWaveNormal(input.positionWS.xz, _Time.y);
                half3 normalWS = normalize(lerp(input.normalWS, waveNormal, 0.8));
                half3 viewDirWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);

                Light mainLight = GetMainLight(input.shadowCoord);
                half ndotl = saturate(dot(normalWS, mainLight.direction));
                half3 diffuse = baseSample * lerp(_DeepColor.rgb, _ShallowColor.rgb, saturate(ndotl)) * mainLight.color * mainLight.shadowAttenuation;

                half3 halfVector = SafeNormalize(mainLight.direction + viewDirWS);
                half specular = pow(saturate(dot(normalWS, halfVector)), lerp(16.0h, 128.0h, _Smoothness));
                half fresnel = pow(1.0h - saturate(dot(normalWS, viewDirWS)), _FresnelPower);

                half3 ambient = lerp(_DeepColor.rgb, _ShallowColor.rgb, 0.35) * _AmbientColor.rgb;
                half3 color = ambient + diffuse + specular * mainLight.color + fresnel * 0.25h;
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
