using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace SkillTemplates.URP
{
    public sealed class FullscreenTemplateFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public sealed class Settings
        {
            public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
            public Material material;
            public string profilerTag = "Skill Fullscreen Pass";
        }

        private sealed class FullscreenTemplatePass : ScriptableRenderPass
        {
            private readonly Material material;
            private readonly ProfilingSampler profilingSampler;
            private RTHandle sourceTarget;
            private RTHandle temporaryTarget;

            public FullscreenTemplatePass(string profilerTag, Material material)
            {
                this.material = material;
                profilingSampler = new ProfilingSampler(profilerTag);
            }

            public void SetTarget(RTHandle colorTargetHandle)
            {
                sourceTarget = colorTargetHandle;
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
                    name: "_SkillFullscreenTemp");
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
        private FullscreenTemplatePass pass;

        public override void Create()
        {
            pass = new FullscreenTemplatePass(settings.profilerTag, settings.material)
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

            pass.SetTarget(renderer.cameraColorTargetHandle);
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
