#ifndef SKILL_SDF_PRIMITIVES_HLSL
#define SKILL_SDF_PRIMITIVES_HLSL

// Sphere SDF
float sdSphere(float3 p, float radius)
{
    return length(p) - radius;
}

// Box SDF (axis-aligned)
float sdBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Torus SDF (major radius r, tube radius t)
float sdTorus(float3 p, float2 rt)
{
    float2 q = float2(length(p.xz) - rt.x, p.y);
    return length(q) - rt.y;
}

// Capsule SDF (between points a and b, radius r)
float sdCapsule(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// Boolean operations
float opUnion(float d1, float d2)
{
    return min(d1, d2);
}

float opSubtraction(float d1, float d2)
{
    return max(-d1, d2);
}

float opIntersection(float d1, float d2)
{
    return max(d1, d2);
}

// Smooth minimum (polynomial)
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(b, a, h) - k * h * (1.0 - h);
}

// 2D rotation matrix
float2x2 rot2D(float angle)
{
    float s = sin(angle), c = cos(angle);
    return float2x2(c, -s, s, c);
}

#endif // SKILL_SDF_PRIMITIVES_HLSL
