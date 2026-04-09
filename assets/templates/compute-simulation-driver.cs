using UnityEngine;

namespace SkillTemplates.URP
{
    public sealed class ComputeSimulationDriver : MonoBehaviour
    {
        private const int ThreadGroupSize = 8;

        [SerializeField] private ComputeShader simulationCompute;
        [SerializeField] private Vector2Int resolution = new Vector2Int(512, 512);
        [SerializeField] private float dissipation = 0.02f;
        [SerializeField] private Vector2 brushPosition = new Vector2(0.5f, 0.5f);
        [SerializeField] private float brushRadius = 0.08f;
        [SerializeField] private float brushStrength = 1.0f;

        public RenderTexture CurrentState => currentState;

        private int updateKernel = -1;
        private RenderTexture currentState;
        private RenderTexture nextState;

        private void OnEnable()
        {
            if (simulationCompute == null)
            {
                return;
            }

            updateKernel = simulationCompute.FindKernel("UpdateState");
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
            if (simulationCompute == null || updateKernel < 0 || currentState == null || nextState == null)
            {
                return;
            }

            simulationCompute.SetTexture(updateKernel, "_CurrentState", currentState);
            simulationCompute.SetTexture(updateKernel, "_NextState", nextState);
            simulationCompute.SetFloat("_DeltaTime", Time.deltaTime);
            simulationCompute.SetFloat("_Dissipation", dissipation);
            simulationCompute.SetVector("_BrushPosition", brushPosition);
            simulationCompute.SetFloat("_BrushRadius", brushRadius);
            simulationCompute.SetFloat("_BrushStrength", brushStrength);
            simulationCompute.SetVector("_TextureSize", new Vector4(resolution.x, resolution.y, 0f, 0f));

            int groupsX = Mathf.CeilToInt(resolution.x / (float)ThreadGroupSize);
            int groupsY = Mathf.CeilToInt(resolution.y / (float)ThreadGroupSize);
            simulationCompute.Dispatch(updateKernel, groupsX, groupsY, 1);
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
                name = $"{nameof(ComputeSimulationDriver)}_{resolution.x}x{resolution.y}",
                enableRandomWrite = true,
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
