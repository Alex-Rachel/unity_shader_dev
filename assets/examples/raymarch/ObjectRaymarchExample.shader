Shader "SkillExamples/URP/Raymarch/ObjectRaymarchExample"
{
    Properties
    {
        _SurfaceColor("Surface Color", Color) = (0.4, 0.8, 1.0, 1.0)
        _AmbientColor("Ambient Color", Color) = (0.08, 0.10, 0.14, 1.0)
        _MaxDistance("Max Distance", Float) = 8.0
        _MaxSteps("Max Steps", Range(8, 256)) = 96
        _SurfaceEpsilon("Surface Epsilon", Float) = 0.001
        _GlowStrength("Glow Strength", Range(0.0, 2.0)) = 0.2
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
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _SurfaceColor;
                float4 _AmbientColor;
                float _MaxDistance;
                float _MaxSteps;
                float _SurfaceEpsilon;
                float _GlowStrength;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
                float3 cameraOS : TEXCOORD1;
            };

            float SphereSdf(float3 p, float radius)
            {
                return length(p) - radius;
            }

            float SceneSdf(float3 p)
            {
                float sphere = SphereSdf(p, 0.28);
                float orbitSphere = SphereSdf(p - float3(0.23, 0.08, 0.0), 0.12);
                return min(sphere, orbitSphere);
            }

            float3 EstimateNormal(float3 p)
            {
                const float e = 0.001;
                return normalize(float3(
                    SceneSdf(p + float3(e, 0.0, 0.0)) - SceneSdf(p - float3(e, 0.0, 0.0)),
                    SceneSdf(p + float3(0.0, e, 0.0)) - SceneSdf(p - float3(0.0, e, 0.0)),
                    SceneSdf(p + float3(0.0, 0.0, e)) - SceneSdf(p - float3(0.0, 0.0, e))
                ));
            }

            bool IntersectBox(float3 ro, float3 rd, float3 bmin, float3 bmax, out float tNear, out float tFar)
            {
                float3 invDir = 1.0 / max(abs(rd), 1e-5) * sign(rd);
                float3 t0 = (bmin - ro) * invDir;
                float3 t1 = (bmax - ro) * invDir;
                float3 tMin3 = min(t0, t1);
                float3 tMax3 = max(t0, t1);
                tNear = max(max(tMin3.x, tMin3.y), tMin3.z);
                tFar = min(min(tMax3.x, tMax3.y), tMax3.z);
                return tFar >= max(tNear, 0.0);
            }

            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionOS = input.positionOS.xyz;
                output.cameraOS = TransformWorldToObject(GetCameraPositionWS());
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 rayOrigin = input.cameraOS;
                float3 rayDir = normalize(input.positionOS - input.cameraOS);

                float tNear;
                float tFar;
                if (!IntersectBox(rayOrigin, rayDir, float3(-0.5, -0.5, -0.5), float3(0.5, 0.5, 0.5), tNear, tFar))
                {
                    clip(-1);
                }

                float travel = max(tNear, 0.0);
                float glow = 0.0;

                [loop]
                for (int stepIndex = 0; stepIndex < (int)_MaxSteps; stepIndex++)
                {
                    float3 p = rayOrigin + rayDir * travel;
                    float distanceToSurface = SceneSdf(p);
                    glow += exp(-20.0 * abs(distanceToSurface)) * 0.02;

                    if (distanceToSurface < _SurfaceEpsilon)
                    {
                        float3 normalOS = EstimateNormal(p);
                        float3 normalWS = normalize(TransformObjectToWorldNormal(normalOS));
                        float3 lightDirWS = normalize(float3(0.35, 0.75, 0.2));
                        float ndotl = saturate(dot(normalWS, lightDirWS));
                        float3 color = _AmbientColor.rgb + _SurfaceColor.rgb * ndotl + glow * _GlowStrength;
                        return half4(color, 1.0);
                    }

                    travel += distanceToSurface;
                    if (travel > min(tFar, _MaxDistance))
                    {
                        break;
                    }
                }

                clip(-1);
                return 0;
            }
            ENDHLSL
        }
    }
}
