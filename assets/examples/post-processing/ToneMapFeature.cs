using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace SkillExamples.URP.PostProcessing
{
    public sealed class ToneMapFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public sealed class Settings
        {
            public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
            public Material material;
            [Range(0.0f, 5.0f)] public float exposure = 1.0f;
        }

        private sealed class ToneMapPass : ScriptableRenderPass
        {
            private readonly ProfilingSampler profilingSampler = new ProfilingSampler("ToneMapPass");
            private readonly Material material;
            private readonly float exposure;

            private RTHandle sourceTarget;
            private RTHandle temporaryTarget;

            public ToneMapPass(Material material, float exposure)
            {
                this.material = material;
                this.exposure = exposure;
            }

            public void SetSource(RTHandle source)
            {
                sourceTarget = source;
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
                descriptor.depthBufferBits = 0;
                RenderingUtils.ReAllocateIfNeeded(
                    ref temporaryTarget,
                    descriptor,
                    FilterMode.Bilinear,
                    TextureWrapMode.Clamp,
                    name: "_ToneMapTemp");
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (material == null || sourceTarget == null || temporaryTarget == null)
                {
                    return;
                }

                CommandBuffer cmd = CommandBufferPool.Get();
                using (new ProfilingScope(cmd, profilingSampler))
                {
                    material.SetFloat("_Exposure", exposure);
                    material.SetTexture("_SourceTexture", sourceTarget);
                    Blitter.BlitCameraTexture(cmd, sourceTarget, temporaryTarget, material, 0);
                    Blitter.BlitCameraTexture(cmd, temporaryTarget, sourceTarget);
                }

                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public void Dispose()
            {
                if (temporaryTarget != null)
                {
                    temporaryTarget.Release();
                    temporaryTarget = null;
                }
            }
        }

        public Settings settings = new Settings();
        private ToneMapPass pass;

        public override void Create()
        {
            pass = new ToneMapPass(settings.material, settings.exposure)
            {
                renderPassEvent = settings.passEvent
            };
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (settings.material == null)
            {
                return;
            }

            pass.SetSource(renderer.cameraColorTargetHandle);
            renderer.EnqueuePass(pass);
        }

        protected override void Dispose(bool disposing)
        {
            if (pass != null)
            {
                pass.Dispose();
            }

            base.Dispose(disposing);
        }
    }
}
