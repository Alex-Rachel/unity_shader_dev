#ifndef SKILL_WAVE_FUNCTIONS_HLSL
#define SKILL_WAVE_FUNCTIONS_HLSL

// Sample wave height at a given xz position and time
// Requires: _WaveFrequency, _WaveSpeed, _WaveAmplitude in CBUFFER
float SampleWaveHeight(float2 xz, float time, float frequency, float speed, float amplitude)
{
    float waveA = sin(xz.x * frequency + time * speed);
    float waveB = cos(xz.y * (frequency * 0.73) - time * (speed * 1.11));
    return (waveA + waveB) * amplitude;
}

// Sample wave normal via finite differences
float3 SampleWaveNormal(float2 xz, float time, float frequency, float speed, float amplitude)
{
    float epsilon = 0.05;
    float h = SampleWaveHeight(xz, time, frequency, speed, amplitude);
    float hx = SampleWaveHeight(xz + float2(epsilon, 0.0), time, frequency, speed, amplitude);
    float hz = SampleWaveHeight(xz + float2(0.0, epsilon), time, frequency, speed, amplitude);
    return normalize(float3(h - hx, epsilon, h - hz));
}

#endif // SKILL_WAVE_FUNCTIONS_HLSL
