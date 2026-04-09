using UnityEngine;

namespace SkillTemplates.URP
{
    public sealed class PingPongSimulationDriver : MonoBehaviour
    {
        [SerializeField] private Material updateMaterial;
        [SerializeField] private Vector2Int resolution = new Vector2Int(512, 512);
        [SerializeField] private float dissipation = 0.02f;
        [SerializeField] private Vector2 brushPosition = new Vector2(0.5f, 0.5f);
        [SerializeField] private float brushRadius = 0.08f;
        [SerializeField] private float brushStrength = 1.0f;

        public RenderTexture CurrentState => currentState;

        private RenderTexture currentState;
        private RenderTexture nextState;
        private Vector2Int lastResolution;

        private void OnEnable()
        {
            AllocateTextures();
            Clear(currentState);
            Clear(nextState);
            lastResolution = resolution;
        }

        private void OnDisable()
        {
            ReleaseTexture(ref currentState);
            ReleaseTexture(ref nextState);
        }

        private void OnValidate()
        {
            if (resolution != lastResolution && Application.isPlaying)
            {
                ReleaseTexture(ref currentState);
                ReleaseTexture(ref nextState);
                AllocateTextures();
                Clear(currentState);
                Clear(nextState);
                lastResolution = resolution;
            }
        }

        private void Update()
        {
            if (updateMaterial == null || currentState == null || nextState == null)
            {
                return;
            }

            updateMaterial.SetTexture("_PreviousState", currentState);
            updateMaterial.SetFloat("_DeltaTime", Time.deltaTime);
            updateMaterial.SetFloat("_Dissipation", dissipation);
            updateMaterial.SetVector("_BrushPosition", new Vector4(brushPosition.x, brushPosition.y, 0f, 0f));
            updateMaterial.SetFloat("_BrushRadius", brushRadius);
            updateMaterial.SetFloat("_BrushStrength", brushStrength);

            // Note: Graphics.Blit is used here for simplicity and URP compatibility mode support.
            // For Unity 6+ RenderGraph workflows, consider replacing with Blitter.BlitCameraTexture
            // or CommandBuffer.Blit depending on the render pass context.
            Graphics.Blit(currentState, nextState, updateMaterial, 0);
            Swap();
        }

        private void AllocateTextures()
        {
            currentState = CreateStateTexture();
            nextState = CreateStateTexture();
        }

        private RenderTexture CreateStateTexture()
        {
            var texture = new RenderTexture(resolution.x, resolution.y, 0, RenderTextureFormat.ARGBHalf)
            {
                name = $"{nameof(PingPongSimulationDriver)}_{resolution.x}x{resolution.y}",
                enableRandomWrite = false,
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Bilinear
            };

            texture.Create();
            return texture;
        }

        private static void Clear(RenderTexture texture)
        {
            var active = RenderTexture.active;
            RenderTexture.active = texture;
            GL.Clear(false, true, Color.clear);
            RenderTexture.active = active;
        }

        private static void ReleaseTexture(ref RenderTexture texture)
        {
            if (texture == null)
            {
                return;
            }

            texture.Release();
            Destroy(texture);
            texture = null;
        }

        private void Swap()
        {
            RenderTexture previousCurrent = currentState;
            currentState = nextState;
            nextState = previousCurrent;
        }
    }
}
