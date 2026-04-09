using UnityEngine;

namespace SkillExamples.URP.Fluid
{
    public sealed class FluidSimulationDriver : MonoBehaviour
    {
        [SerializeField] private Material updateMaterial;
        [SerializeField] private Material previewMaterial;
        [SerializeField] private Vector2Int resolution = new Vector2Int(512, 512);
        [SerializeField] private float dissipation = 0.025f;
        [SerializeField] private Vector2 brushPosition = new Vector2(0.5f, 0.5f);
        [SerializeField] private float brushRadius = 0.1f;
        [SerializeField] private float brushStrength = 2.0f;

        private RenderTexture currentState;
        private RenderTexture nextState;

        private void OnEnable()
        {
            AllocateTextures();
            Clear(currentState);
            Clear(nextState);
        }

        private void OnDisable()
        {
            ReleaseTexture(ref currentState);
            ReleaseTexture(ref nextState);
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

            Graphics.Blit(currentState, nextState, updateMaterial, 0);
            Swap();

            if (previewMaterial != null)
            {
                previewMaterial.SetTexture("_StateTex", currentState);
            }
        }

        private void AllocateTextures()
        {
            currentState = CreateStateTexture();
            nextState = CreateStateTexture();
        }

        private RenderTexture CreateStateTexture()
        {
            RenderTexture texture = new RenderTexture(resolution.x, resolution.y, 0, RenderTextureFormat.ARGBHalf);
            texture.name = "FluidState";
            texture.wrapMode = TextureWrapMode.Clamp;
            texture.filterMode = FilterMode.Bilinear;
            texture.Create();
            return texture;
        }

        private static void Clear(RenderTexture texture)
        {
            RenderTexture previous = RenderTexture.active;
            RenderTexture.active = texture;
            GL.Clear(false, true, Color.clear);
            RenderTexture.active = previous;
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
