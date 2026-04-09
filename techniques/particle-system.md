# Particle System

<!-- GENERATED:NOTICE:START -->
> Execution status: prototype algorithm reference.
> Treat code blocks in this file as GLSL-style algorithm notes unless a section explicitly says Unity URP Executable.
> For runnable Unity output, start from [the authoring contract](../reference/pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates).
<!-- GENERATED:NOTICE:END -->

<!-- GENERATED:TOC:START -->
## Table of Contents

- [Unity URP Note](#unity-urp-note)
- [URP Integration Guidance](#urp-integration-guidance)
- [Key Constraints](#key-constraints)
  - [Step 1: Hash Random Functions](#step-1-hash-random-functions)
  - [Step 2: Particle Lifecycle Management](#step-2-particle-lifecycle-management)
  - [Step 3: Stateless Particle Position Computation](#step-3-stateless-particle-position-computation)
  - [Step 4: Buffer-Stored Particle State (Stateful System)](#step-4-buffer-stored-particle-state-stateful-system)
  - [Step 5: Particle Rendering �?Metaball Style](#step-5-particle-rendering-metaball-style)
  - [Step 6: Frame Feedback Motion Blur](#step-6-frame-feedback-motion-blur)
  - [Step 7: HSV Coloring & Star Glare Effect](#step-7-hsv-coloring-star-glare-effect)
- [Complete Code Template](#complete-code-template)
- [Common Variants](#common-variants)
  - [Variant 1: Metaball Polar Coordinate Particles](#variant-1-metaball-polar-coordinate-particles)
  - [Variant 2: Buffer Storage + Boids Flocking Behavior](#variant-2-buffer-storage-boids-flocking-behavior)
  - [Variant 3: Verlet Integration Cloth Simulation](#variant-3-verlet-integration-cloth-simulation)
  - [Variant 4: 3D Particles + Ray Rendering](#variant-4-3d-particles-ray-rendering)
  - [Variant 5: Raindrop Particles (3D Scene Integration)](#variant-5-raindrop-particles-3d-scene-integration)
  - [Variant 6: Vortex/Storm Particle System (Sandstorm, Blizzard, Whirlwind, etc.)](#variant-6-vortexstorm-particle-system-sandstorm-blizzard-whirlwind-etc)
  - [Variant 7: Meteor/Trail Line Rendering (Single-Pass Stateless)](#variant-7-meteortrail-line-rendering-single-pass-stateless)
  - [Variant 8: Fountain/Upward Jet Particle System (Single-Pass Stateless)](#variant-8-fountainupward-jet-particle-system-single-pass-stateless)
  - [Variant 9: Campfire/Flame Particle System (Single-Pass Stateless)](#variant-9-campfireflame-particle-system-single-pass-stateless)
  - [Variant 10: Spiral Array/Magic Particle System (Single-Pass Stateless)](#variant-10-spiral-arraymagic-particle-system-single-pass-stateless)
- [Performance & Composition](#performance-composition)
- [Further Reading](#further-reading)
<!-- GENERATED:TOC:END -->










## Unity URP Note
Implement particle effects in URP using one of two patterns:
- Stateless fullscreen or material shaders for stylized spark, starfield, trail, and burst effects.
- Stateful ping-pong simulation targets for particles that need persistent position, velocity, lifetime, or density.
## URP Integration Guidance
- For pure screen-space particles, run a fullscreen pass and derive particle contributions in the fragment stage.
- For world-space particles, expose the logic through mesh or billboard materials, VFX Graph interop, or GPU-instanced draw paths.
- For stateful simulation, keep particle attributes in one or more RenderTexture/RTHandle pairs and advance them from C# each frame.
- Translate prototype variables such as iResolution, iTime, iMouse, and iChannel0 into URP material properties, bound textures, and C#-driven interaction data.
## Key Constraints
- All non-void helper functions must return on every path.
- Cycle particles with mod(time - offset, period) rather than ad hoc floor-based resets.
- Budget brightness carefully when many particles overlap; clamp or tone-map after accumulation.
- Prefer smooth distance falloffs for trails and lines rather than singular inverse-distance spikes.
### Step 1: Hash Random Functions
```glsl
// 1D -> 1D hash, returns [0, 1)
float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}

// 1D -> 2D hash
vec2 hash12(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// 3D -> 3D hash
vec3 hash33(vec3 p) {
    p = fract(p * vec3(443.897, 397.297, 491.187));
    p += dot(p.zxy, p.yxz + 19.19);
    return fract(vec3(p.x * p.y, p.z * p.x, p.y * p.z)) - 0.5;
}
```

### Step 2: Particle Lifecycle Management
```glsl
#define NUM_PARTICLES 100
#define LIFETIME_MIN 1.0
#define LIFETIME_MAX 3.0
#define START_TIME 2.0

// Returns: x = normalized age [0,1], y = life cycle number
vec2 particleAge(int id, float time) {
    float spawnTime = START_TIME * hash11(float(id) * 2.0);
    float lifetime = mix(LIFETIME_MIN, LIFETIME_MAX, hash11(float(id) * 3.0 - 35.0));
    float age = mod(time - spawnTime, lifetime);
    float run = floor((time - spawnTime) / lifetime);
    return vec2(age / lifetime, run);
}
```

### Step 3: Stateless Particle Position Computation
```glsl
#define GRAVITY vec2(0.0, -4.5)
#define DRIFT_MAX vec2(0.28, 0.28)

// Harmonic superposition for smooth main trajectory
float harmonics(vec3 freq, vec3 amp, vec3 phase, float t) {
    float val = 0.0;
    for (int h = 0; h < 3; h++)
        val += amp[h] * cos(t * freq[h] * 6.2832 + phase[h] / 360.0 * 6.2832);
    return (1.0 + val) / 2.0;
}

vec2 particlePosition(int id, float time) {
    vec2 ageInfo = particleAge(id, time);
    float age = ageInfo.x;
    float run = ageInfo.y;

    float slowTime = time * 0.1;
    vec2 mainPos = vec2(
        harmonics(vec3(0.4, 0.66, 0.78), vec3(0.8, 0.24, 0.18), vec3(0.0, 45.0, 55.0), slowTime),
        harmonics(vec3(0.415, 0.61, 0.82), vec3(0.72, 0.28, 0.15), vec3(90.0, 120.0, 10.0), slowTime)
    );

    vec2 drift = DRIFT_MAX * (vec2(hash11(float(id) * 3.0 + run * 4.0),
                                    hash11(float(id) * 7.0 - run * 2.5)) - 0.5) * age;
    vec2 grav = GRAVITY * age * age * 0.5;

    return mainPos + drift + grav;
}
```

### Step 4: Buffer-Stored Particle State (Stateful System)
```glsl
// === Buffer A: Particle Physics Update ===
// IMPORTANT: Multi-pass system warning: each fragment shader is compiled independently, helper functions must be redefined in each shader!
#define NUM_PARTICLES 40
#define MAX_VEL 0.5
#define MAX_ACC 3.0
#define RESIST 0.2
#define DT 0.03

// Helper functions that must be defined in the Buffer A shader
float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}

vec2 hash12(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec4 loadParticle(float i) {
    return texelFetch(iChannel0, ivec2(i, 0), 0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (fragCoord.y > 0.5 || fragCoord.x > float(NUM_PARTICLES)) discard;

    float id = floor(fragCoord.x);
    vec2 res = iResolution.xy / iResolution.y;

    if (iFrame < 5) {
        vec2 rng = hash12(id);
        fragColor = vec4(0.1 + 0.8 * rng * res, 0.0, 0.0);
        return;
    }

    vec4 particle = loadParticle(id); // xy = pos, zw = vel
    vec2 pos = particle.xy;
    vec2 vel = particle.zw;

    vec2 force = vec2(0.0);
    force += 0.8 * (1.0 / abs(pos) - 1.0 / abs(res - pos)); // boundary repulsion
    for (float i = 0.0; i < float(NUM_PARTICLES); i++) {     // inter-particle interaction
        if (i == id) continue;
        vec4 other = loadParticle(i);
        vec2 w = pos - other.xy;
        float d = length(w);
        if (d > 0.0)
            force -= w * (6.3 + log(d * d * 0.02)) / exp(d * d * 2.4) / d;
    }
    force -= vel * RESIST / DT; // friction

    vec2 acc = force;
    float a = length(acc);
    acc *= a > MAX_ACC ? MAX_ACC / a : 1.0;
    vel += acc * DT;
    float v = length(vel);
    vel *= v > MAX_VEL ? MAX_VEL / v : 1.0;
    pos += vel * DT;

    fragColor = vec4(pos, vel);
}
```

### Step 5: Particle Rendering �?Metaball Style
// IMPORTANT: Multi-pass system warning: Image shader must define all the following helper functions (compiled independently)!
```glsl
#define BRIGHTNESS 0.002
#define COLOR_START vec3(0.0, 0.64, 0.2)
#define COLOR_END vec3(0.06, 0.35, 0.85)

// Helper functions that must be defined in the Image shader
float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}

vec2 hash12(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec4 loadParticle(float i) {
    return texelFetch(iChannel0, ivec2(i, 0), 0);
}

// HSV to RGB (correct implementation)
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 renderParticles(vec2 uv) {
    vec3 col = vec3(0.0);
    float totalWeight = 0.0;
    for (int i = 0; i < NUM_PARTICLES; i++) {
        vec4 particle = loadParticle(float(i));
        vec2 p = uv - particle.xy;
        float mb = BRIGHTNESS / dot(p, p);
        totalWeight += mb;
        float ratio = length(particle.zw) / MAX_VEL;
        vec3 pcol = mix(COLOR_START, COLOR_END, ratio);
        col = mix(col, pcol, mb / totalWeight);
    }
    totalWeight /= float(NUM_PARTICLES);
    col = normalize(col) * clamp(totalWeight, 0.0, 0.4);
    return col;
}
```

### Step 6: Frame Feedback Motion Blur
```glsl
// IMPORTANT: Ping-pong brightness budget (most common washout cause!):
// Steady-state brightness = singleFrameContribution / (1 - TRAIL_DECAY)
// decay=0.88 �?8.3x amplification, decay=0.95 �?20x amplification
// Budget formula: N_particles x (numerator/epsilon) x 1/(1-decay) < 10.0
//
// Safe parameter lookup table (decay=0.88, 8.3x amplification):
//   20 particles �?single particle peak < 0.06  (numerator=0.002, epsilon=0.03)
//   50 particles �?single particle peak < 0.024 (numerator=0.001, epsilon=0.04)
//  100 particles �?single particle peak < 0.012 (numerator=0.0005, epsilon=0.04)
//
// Safe parameter lookup table (decay=0.92, 12.5x amplification):
//   20 particles �?single particle peak < 0.04  (numerator=0.001, epsilon=0.03)
//   50 particles �?single particle peak < 0.016 (numerator=0.0005, epsilon=0.03)
//  100 particles �?single particle peak < 0.008 (numerator=0.0003, epsilon=0.04)
#define TRAIL_DECAY 0.88

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 prev = texture(iChannel0, uv).rgb * TRAIL_DECAY;
    vec3 current = renderParticles(fragCoord / iResolution.y);
    fragColor = vec4(prev + current, 1.0);
}
```

### Step 7: HSV Coloring & Star Glare Effect
```glsl
// HSV to RGB (correct implementation)
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Star glare: thin rays in horizontal/vertical/diagonal directions
float starGlare(vec2 relPos, float intensity) {
    vec2 stretch = vec2(9.0, 0.32);
    float dh = length(relPos * stretch);
    float dv = length(relPos * stretch.yx);
    vec2 diagPos = 0.707 * vec2(dot(relPos, vec2(1, 1)), dot(relPos, vec2(1, -1)));
    float dd1 = length(diagPos * vec2(13.0, 0.61));
    float dd2 = length(diagPos * vec2(0.61, 13.0));
    float glare = 0.25 / (dh * 3.0 + 0.01)
                + 0.25 / (dv * 3.0 + 0.01)
                + 0.19 / (dd1 * 3.0 + 0.01)
                + 0.19 / (dd2 * 3.0 + 0.01);
    return glare * intensity;
}
```

## Complete Code Template

Single-pass stateless particle system, runs directly in ShaderToy-style prototype's Image tab:

```glsl
// === Particle System �?Stateless Single-Pass Template ===

#define NUM_PARTICLES 80
#define LIFETIME_MIN 1.0
#define LIFETIME_MAX 3.5
#define START_TIME 2.5
#define BRIGHTNESS 0.00004
#define GRAVITY vec2(0.0, -2.0)
#define DRIFT_SPEED 0.2
#define HUE_SHIFT 0.035
#define TRAIL_DECAY 0.92
#define STAR_ENABLED 1

#define PI 3.14159265
#define TAU 6.28318530

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float harmonics3(vec3 freq, vec3 amp, vec3 phase, float t) {
    float val = 0.0;
    for (int h = 0; h < 3; h++)
        val += amp[h] * cos(t * freq[h] * TAU + phase[h] / 360.0 * TAU);
    return (1.0 + val) * 0.5;
}

vec3 getLifecycle(int id, float time) {
    float spawn = START_TIME * hash11(float(id) * 2.0);
    float life = mix(LIFETIME_MIN, LIFETIME_MAX, hash11(float(id) * 3.0 - 35.0));
    float age = mod(time - spawn, life);
    float run = floor((time - spawn) / life);
    return vec3(age / life, run, spawn);
}

vec2 getPosition(int id, float time) {
    vec3 lc = getLifecycle(id, time);
    float age = lc.x;
    float run = lc.y;

    float tfact = mix(6.0, 20.0, hash11(float(id) * 2.0 + 94.0 + run * 1.5));
    float pt = (run * lc.x * mix(LIFETIME_MIN, LIFETIME_MAX, hash11(float(id)*3.0-35.0)) + lc.z) * (-1.0/tfact + 1.0) + time / tfact;

    vec2 mainPos = vec2(
        harmonics3(vec3(0.4, 0.66, 0.78), vec3(0.8, 0.24, 0.18), vec3(0.0, 45.0, 55.0), pt),
        harmonics3(vec3(0.415, 0.61, 0.82), vec3(0.72, 0.28, 0.15), vec3(90.0, 120.0, 10.0), pt)
    ) + vec2(0.35, 0.15);

    vec2 drift = DRIFT_SPEED * (vec2(
        hash11(float(id) * 3.0 - 23.0 + run * 4.0),
        hash11(float(id) * 7.0 + 632.0 - run * 2.5)
    ) - 0.5) * age;

    vec2 grav = GRAVITY * age * age * 0.004;

    return (mainPos + drift + grav) * vec2(0.6, 0.45);
}

float starGlare(vec2 rel) {
    #if STAR_ENABLED == 0
        return 0.0;
    #endif
    vec2 stretchHV = vec2(9.0, 0.32);
    float dh = length(rel * stretchHV);
    float dv = length(rel * stretchHV.yx);
    vec2 dRel = 0.707 * vec2(dot(rel, vec2(1, 1)), dot(rel, vec2(1, -1)));
    vec2 stretchDiag = vec2(13.0, 0.61);
    float dd1 = length(dRel * stretchDiag);
    float dd2 = length(dRel * stretchDiag.yx);
    return 0.25 / (dh * 3.0 + 0.01) + 0.25 / (dv * 3.0 + 0.01)
         + 0.19 / (dd1 * 3.0 + 0.01) + 0.19 / (dd2 * 3.0 + 0.01);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xx;
    float time = iTime * 0.75;

    vec3 col = vec3(0.0);

    for (int i = 1; i < NUM_PARTICLES; i++) {
        vec3 lc = getLifecycle(i, time);
        float age = lc.x;
        float run = lc.y;

        vec2 ppos = getPosition(i, time);
        vec2 rel = uv - ppos;
        float dist = length(rel);

        float baseInt = mix(0.1, 3.2, hash11(run * 4.0 + float(i) - 55.0));
        float glow = 1.0 / (dist * 3.0 + 0.015);

        float star = starGlare(rel);
        float intensity = baseInt * pow(glow + star, 2.3) / 40000.0;

        intensity *= (1.0 - age);
        intensity *= smoothstep(0.0, 0.15, age);
        float sparkFreq = mix(2.5, 6.0, hash11(float(i) * 5.0 + 72.0 - run * 1.8));
        intensity *= 0.5 * sin(sparkFreq * TAU * time) + 1.0;

        float hue = mix(-0.13, 0.13, hash11(float(i) + 124.0 + run * 1.5)) + HUE_SHIFT * time;
        float sat = mix(0.5, 0.9, hash11(float(i) * 6.0 + 44.0 + run * 3.3)) * 0.45 / max(intensity, 0.001);
        col += hsv2rgb(vec3(hue, clamp(sat, 0.0, 1.0), intensity));
    }

    col = pow(max(col, 0.0), vec3(1.0 / 2.2));
    fragColor = vec4(col, 1.0);
}
```

## Common Variants

### Variant 1: Metaball Polar Coordinate Particles
```glsl
float d = fract(time * 0.51 + 48934.4238 * sin(float(i) * 692.7398));
float angle = TAU * float(i) / float(NUM_PARTICLES);
vec2 particlePos = d * vec2(cos(angle), sin(angle)) * 4.0;

vec2 p = uv - particlePos;
float mb = 0.84 / dot(p, p);
col = mix(col, mix(startColor, endColor, d), mb / totalSum);
```

### Variant 2: Buffer Storage + Boids Flocking Behavior
```glsl
vec2 sumForce = vec2(0.0);
for (float j = 0.0; j < NUM_PARTICLES; j++) {
    if (j == id) continue;
    vec4 other = texelFetch(iChannel0, ivec2(j, 0), 0);
    vec2 w = pos - other.xy;
    float d = length(w);
    sumForce -= w * (6.3 + log(d * d * 0.02)) / exp(d * d * 2.4) / d;
}
sumForce -= vel * 0.2 / dt;
```

### Variant 3: Verlet Integration Cloth Simulation
```glsl
vec2 newPos = 2.0 * particle.xy - particle.zw + vec2(0.0, -0.6) * dt * dt;
particle.zw = particle.xy;
particle.xy = newPos;

vec4 neighbor = texelFetch(iChannel0, neighborId, 0);
vec2 delta = neighbor.xy - particle.xy;
float dist = length(delta);
float restLength = 0.1;
particle.xy += 0.1 * (dist - restLength) * (delta / dist);
```

### Variant 4: 3D Particles + Ray Rendering
```glsl
vec3 ro = vec3(0.0, 0.0, 2.5);
vec3 rd = normalize(vec3(uv, -0.5));
for (int i = 0; i < numParticles; i++) {
    vec3 pos = texture(iChannel0, vec2(i, 100.0) * w).rgb;
    float d = dot(cross(pos - ro, rd), cross(pos - ro, rd));
    d *= 1000.0;
    float glow = 0.14 / (pow(d, 1.1) + 0.03);
    col += glow * particleColor;
}
```

### Variant 5: Raindrop Particles (3D Scene Integration)
```glsl
float speedScale = 0.0015 * (0.1 + 1.9 * sin(PI * 0.5 * pow(age / lifetime, 2.0)));
particle.x += (windShieldOffset.x + windIntensity * dot(rayRight, windDir)) * fallSpeed * speedScale * dt;
particle.y += (windShieldOffset.y + windIntensity * dot(rayUp, windDir)) * fallSpeed * speedScale * dt;
particle.xy += 0.001 * (randVec2(particle.xy + iTime) - 0.5) * jitterSpeed * dt;
if (particle.z > particle.a) {
    particle.xy = vec2(rand(seedX), rand(seedY)) * iResolution.xy;
    particle.a = lifetimeMin + rand(pid) * (lifetimeMax - lifetimeMin);
    particle.z = 0.0;
}
```

### Variant 6: Vortex/Storm Particle System (Sandstorm, Blizzard, Whirlwind, etc.)

Uses stateless single pass. Key: spiral trajectory + high-visibility particles + vortex eye dark zone + separated background fog layer.

```glsl
// IMPORTANT: Particle color must be 2-3x brighter than background to be visible (sand-colored particles on sand-colored background easily disappear)
// IMPORTANT: Brightness budget: 150 particles x peak(0.005/0.003=1.67) x fade(avg~0.3) �?75, overexposed!
//    Must increase epsilon or decrease numerator. Safe values: numerator=0.002, epsilon=0.008 �?peak=0.25, total=11 �?OK after Reinhard
#define NUM_DUST 150
#define VORTEX_CENTER vec2(0.0)

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;

    vec3 bg = mix(vec3(0.25, 0.18, 0.08), vec3(0.4, 0.28, 0.12), gl_FragCoord.y / iResolution.y);

    vec3 col = vec3(0.0);
    for (int i = 0; i < NUM_DUST; i++) {
        float fi = float(i);
        float life = mix(2.0, 5.0, hash11(fi * 3.7));
        float age = mod(t - hash11(fi * 2.0) * life, life);
        float norm = age / life;

        float initAngle = hash11(fi * 7.3) * 6.2832;
        float initR = 0.05 + hash11(fi * 11.0) * 0.5;
        float angularSpeed = 2.0 / (0.3 + initR);
        float angle = initAngle + norm * angularSpeed;
        float radius = initR + norm * 0.15;

        vec2 pos = VORTEX_CENTER + vec2(cos(angle), sin(angle)) * radius;

        vec2 rel = uv - pos;
        float dist = length(rel);

        float fade = smoothstep(0.0, 0.1, norm) * smoothstep(1.0, 0.5, norm);
        // Safe brightness: peak = 0.002/0.008 = 0.25, x 150 x avg_fade(0.3) �?11 �?Reinhard OK
        float glow = 0.002 / (dist * dist + 0.008) * fade;

        // Particles need to be noticeably brighter than background, use light sand + white blend
        vec3 dustColor = mix(vec3(1.0, 0.9, 0.6), vec3(1.0, 0.95, 0.85), hash11(fi * 5.0));
        col += dustColor * glow;
    }

    float eyeDist = length(uv - VORTEX_CENTER);
    float eye = smoothstep(0.06, 0.15, eyeDist);

    vec3 final = bg + col * eye;
    final = final / (1.0 + final);
    fragColor = vec4(final, 1.0);
}
```

### Variant 7: Meteor/Trail Line Rendering (Single-Pass Stateless)

Meteors, magic projectiles, etc. need elongated glow (stretched luminous lines). **Do not use `1/(distPerp² + tiny_epsilon)` for lines** �?too-small epsilon makes line centers extremely bright and washed out. Use `exp(-dist)` or `smoothstep` for safe line glow.

**IMPORTANT: Common meteor failures**: (1) Star background too dark to see �?must call `starField()` above and ensure stars use Gaussian dots `exp(-dist²*k)` for rendering (2) Meteor trail too faint �?`core` multiplier should be at least 0.15, each step after dividing by `NUM_TRAIL_STEPS` still needs >= 0.005 contribution

```glsl
#define NUM_METEORS 6
#define NUM_TRAIL_STEPS 20

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;

    // Deep blue night sky background + must call starField to draw stars
    vec3 col = vec3(0.005, 0.005, 0.02);
    col += starField(uv);

    for (int m = 0; m < NUM_METEORS; m++) {
        float fm = float(m);
        float cycleTime = mix(3.0, 7.0, hash11(fm * 17.3));
        float meteorTime = mod(t - hash11(fm * 23.7) * cycleTime, cycleTime);
        float travelDuration = mix(0.5, 1.2, hash11(fm * 31.1));

        if (meteorTime > travelDuration + 0.3) continue;

        float angle = mix(-0.4, -1.3, hash11(fm * 41.3));
        vec2 dir = normalize(vec2(cos(angle), sin(angle)));
        vec2 startPos = vec2(
            mix(-0.3, 0.8, hash11(fm * 53.7)),
            mix(0.2, 0.7, hash11(fm * 61.1))
        );
        float speed = mix(1.0, 2.0, hash11(fm * 71.3));
        float headT = clamp(meteorTime / travelDuration, 0.0, 1.0);
        vec2 headPos = startPos + dir * speed * headT;

        float headFade = smoothstep(0.0, 0.1, meteorTime)
                       * smoothstep(travelDuration + 0.3, travelDuration, meteorTime);

        float trailLen = mix(0.15, 0.35, hash11(fm * 83.7));

        for (int s = 0; s < NUM_TRAIL_STEPS; s++) {
            float sf = float(s) / float(NUM_TRAIL_STEPS);
            vec2 samplePos = headPos - dir * trailLen * sf;
            vec2 rel = uv - samplePos;

            float distPerp = abs(dot(rel, vec2(-dir.y, dir.x)));

            // Line width: narrow at head, wide at tail
            float width = mix(0.003, 0.015, sf);
            // core multiplier 0.15 ensures trail is visible even under SwiftShader
            float core = exp(-distPerp / width) * 0.15;

            float trailFade = (1.0 - sf) * (1.0 - sf);
            float intensity = core * trailFade * headFade / float(NUM_TRAIL_STEPS);

            float hue = mix(0.05, 0.12, sf);
            vec3 meteorCol = hsv2rgb(vec3(hue, mix(0.1, 0.4, sf), 1.0));
            col += meteorCol * intensity;
        }

        // Meteor head: bright point
        float headDist = length(uv - headPos);
        float headGlow = headFade * 0.005 / (headDist * headDist + 0.0008);
        col += vec3(1.0, 0.95, 0.85) * headGlow;
    }

    col = col / (1.0 + col);
    col = pow(col, vec3(0.95));
    fragColor = vec4(col, 1.0);
}
```

### Variant 8: Fountain/Upward Jet Particle System (Single-Pass Stateless)

Water/sparks jetting upward from a point, parabolic descent. Key: **Particles must be sharp, individually visible points** (small epsilon), not just a diffuse glow blob. Must include: (1) main water column particles (upward jet + parabola) (2) splash particles (spread sideways after hitting water) (3) water surface/pool visuals.

**IMPORTANT: Most common fountain failure**: Only produces blurry glow without visible individual water droplet trajectories! Must use small epsilon (<=0.002) so each particle is clearly visible as an individual light point. Numerator must also be proportionally reduced to control total brightness.

```glsl
#define NUM_WATER 60
#define NUM_SPLASH 40
#define FOUNTAIN_BASE vec2(0.0, -0.3)
#define WATER_LEVEL -0.3

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;

    // Dark background
    vec3 col = vec3(0.01, 0.02, 0.06);

    // --- Water pool/surface ---
    float waterDist = abs(uv.y - WATER_LEVEL);
    float waterLine = smoothstep(0.01, 0.0, waterDist) * 0.3;
    float waterBody = smoothstep(WATER_LEVEL, WATER_LEVEL - 0.15, uv.y);
    col += vec3(0.02, 0.06, 0.12) * waterBody;
    col += vec3(0.3, 0.5, 0.7) * waterLine;

    // --- Main water column particles: upward jet + parabola ---
    for (int i = 0; i < NUM_WATER; i++) {
        float fi = float(i);
        float lifetime = mix(1.0, 2.0, hash11(fi * 3.7));
        float age = mod(t - hash11(fi * 2.3) * lifetime, lifetime);
        float norm = age / lifetime;

        float spreadAngle = (hash11(fi * 7.3) - 0.5) * 0.6;
        float speed = mix(0.9, 1.6, hash11(fi * 11.0));
        vec2 vel0 = vec2(sin(spreadAngle), cos(spreadAngle)) * speed;

        vec2 pos = FOUNTAIN_BASE + vel0 * age + vec2(0.0, -1.8) * age * age;

        if (pos.y < WATER_LEVEL - 0.02) continue;

        vec2 rel = uv - pos;
        float dist = length(rel);

        float fade = smoothstep(0.0, 0.05, norm) * smoothstep(1.0, 0.6, norm);
        // Sharp light point: small epsilon makes each particle clearly visible as an individual dot
        // peak = 0.004/0.0015 = 2.67, x 60 x avg_fade(0.25) �?40 �?Reinhard OK
        float glow = 0.004 / (dist * dist + 0.0015) * fade;

        vec3 waterCol = mix(vec3(0.5, 0.8, 1.0), vec3(0.9, 0.97, 1.0), hash11(fi * 5.0));
        col += waterCol * glow;
    }

    // --- Splash particles: spread sideways at water surface ---
    for (int i = 0; i < NUM_SPLASH; i++) {
        float fi = float(i) + 200.0;
        float lifetime = mix(0.3, 0.8, hash11(fi * 3.7));
        float age = mod(t - hash11(fi * 2.3) * lifetime, lifetime);
        float norm = age / lifetime;

        float xOffset = (hash11(fi * 7.3) - 0.5) * 0.5;
        vec2 splashBase = vec2(xOffset, WATER_LEVEL);
        float splashAngle = (hash11(fi * 11.0) - 0.5) * 2.5;
        float splashSpeed = mix(0.2, 0.5, hash11(fi * 13.0));
        vec2 splashVel = vec2(sin(splashAngle), abs(cos(splashAngle))) * splashSpeed;

        vec2 pos = splashBase + splashVel * age + vec2(0.0, -2.0) * age * age;
        if (pos.y < WATER_LEVEL - 0.01) continue;

        vec2 rel = uv - pos;
        float dist = length(rel);

        float fade = smoothstep(0.0, 0.05, norm) * smoothstep(1.0, 0.3, norm);
        float glow = 0.002 / (dist * dist + 0.001) * fade;

        col += vec3(0.7, 0.85, 1.0) * glow;
    }

    col = col / (1.0 + col);
    fragColor = vec4(col, 1.0);
}
```

### Variant 9: Campfire/Flame Particle System (Single-Pass Stateless)

Flame effects must include **two layers**: (1) smooth flame body at the base (noise-driven cone gradient) (2) many **discrete ember/spark particles** above, drifting upward and gradually extinguishing. Using only a smooth gradient will be judged as "no particle system."

**IMPORTANT: Most common flame failure**: Only draws a smooth gradient without discrete particles! Must have NUM_SPARKS individual point-like particles drifting out from the flame top.

```glsl
#define NUM_SPARKS 60
#define FIRE_BASE vec2(0.0, -0.35)

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash11(dot(i, vec2(127.1, 311.7)));
    float b = hash11(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7)));
    float c = hash11(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7)));
    float d = hash11(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7)));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;
    vec3 col = vec3(0.02, 0.01, 0.01);

    // --- Layer 1: flame body (smooth noise cone) ---
    vec2 fireUV = uv - FIRE_BASE;
    float fireH = clamp(fireUV.y / 0.5, 0.0, 1.0);
    float width = mix(0.15, 0.01, fireH);
    float n = noise(vec2(fireUV.x * 6.0, fireUV.y * 4.0 - t * 3.0));
    float flameShape = smoothstep(width, 0.0, abs(fireUV.x + (n - 0.5) * 0.08))
                     * smoothstep(-0.02, 0.05, fireUV.y)
                     * smoothstep(0.55, 0.0, fireUV.y);
    vec3 innerCol = vec3(1.0, 0.95, 0.7);
    vec3 outerCol = vec3(1.0, 0.35, 0.05);
    vec3 flameCol = mix(outerCol, innerCol, smoothstep(0.3, 0.8, flameShape));
    col += flameCol * flameShape * 1.5;

    // --- Layer 2: discrete ember particles (required!) ---
    for (int i = 0; i < NUM_SPARKS; i++) {
        float fi = float(i);
        float lifetime = mix(0.8, 2.0, hash11(fi * 3.7));
        float age = mod(t - hash11(fi * 2.3) * lifetime, lifetime);
        float norm = age / lifetime;

        float xSpread = (hash11(fi * 7.3) - 0.5) * 0.2;
        float riseSpeed = mix(0.3, 0.7, hash11(fi * 11.0));
        float wobble = sin(t * 3.0 + fi * 2.7) * 0.03 * norm;
        vec2 sparkPos = FIRE_BASE + vec2(0.0, 0.25)
                      + vec2(xSpread + wobble, riseSpeed * age);

        vec2 rel = uv - sparkPos;
        float dist = length(rel);

        float fade = smoothstep(0.0, 0.1, norm) * smoothstep(1.0, 0.3, norm);
        // peak = 0.003/0.0008 = 3.75, x 60 x avg_fade(0.2) �?45 �?Reinhard OK
        float glow = 0.003 / (dist * dist + 0.0008) * fade;

        float hue = mix(0.03, 0.12, norm);
        vec3 sparkCol = hsv2rgb(vec3(hue, mix(0.9, 0.3, norm), 1.0));
        col += sparkCol * glow;
    }

    col = col / (1.0 + col);
    col = pow(col, vec3(0.95));
    fragColor = vec4(col, 1.0);
}
```

### Variant 10: Spiral Array/Magic Particle System (Single-Pass Stateless)

Magic effects, spiral ascent, magic circles, etc. require particles arranged in **geometric arrays** with **iridescent shimmer**. Key: particles must be individually visible glowing points (not a blurry glow blob), and the spiral structure must be clearly discernible.

**IMPORTANT: Most common magic failure**: Only produces a blob of blurry light (diffuse glow blob) without visible individual particles or geometric structure! Ensure each particle is an independently visible small light point, and the overall arrangement forms spiral/ring/other geometric shapes. Reduce epsilon to make each particle sharper (small light dot) rather than a large blurry halo.

```glsl
#define NUM_SPIRAL 80
#define NUM_RING 40
#define WAND_TIP vec2(0.0, -0.15)

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;
    vec3 col = vec3(0.01, 0.005, 0.02);

    // --- Layer 1: spiral ascending particles (emanating from emission point) ---
    for (int i = 0; i < NUM_SPIRAL; i++) {
        float fi = float(i);
        float lifetime = mix(2.0, 4.0, hash11(fi * 3.7));
        float age = mod(t - hash11(fi * 2.3) * lifetime, lifetime);
        float norm = age / lifetime;

        // Spiral trajectory: angle increases with time and height
        float baseAngle = fi / float(NUM_SPIRAL) * 6.2832 * 3.0;
        float spiralAngle = baseAngle + norm * 8.0 + t * 1.5;
        float radius = 0.05 + norm * 0.25;
        float height = norm * 0.7;

        vec2 pos = WAND_TIP + vec2(cos(spiralAngle) * radius, height);

        vec2 rel = uv - pos;
        float dist = length(rel);

        float fade = smoothstep(0.0, 0.08, norm) * smoothstep(1.0, 0.4, norm);
        // Sharp small light point: small epsilon makes particles clearly visible as individual dots
        // peak = 0.004/0.0006 = 6.67, x 80 x avg_fade(0.25) �?133 �?Reinhard OK
        float glow = 0.004 / (dist * dist + 0.0006) * fade;

        // Iridescent effect: hue varies with particle ID + time, producing rainbow shimmer
        float hue = fract(fi / float(NUM_SPIRAL) + t * 0.3 + norm * 0.5);
        float shimmer = 0.7 + 0.3 * sin(t * 8.0 + fi * 3.7);
        vec3 pCol = hsv2rgb(vec3(hue, 0.7, 1.0)) * shimmer;
        col += pCol * glow;
    }

    // --- Layer 2: magic circle ring (horizontally rotating light point ring) ---
    float ringY = WAND_TIP.y + 0.45;
    float ringRadius = 0.2 + 0.03 * sin(t * 2.0);
    for (int i = 0; i < NUM_RING; i++) {
        float fi = float(i);
        float angle = fi / float(NUM_RING) * 6.2832 + t * 2.0;
        // Simulated perspective: ellipse (cos full width, sin compressed)
        vec2 ringPos = vec2(cos(angle) * ringRadius, ringY + sin(angle) * ringRadius * 0.3);

        vec2 rel = uv - ringPos;
        float dist = length(rel);

        float pulse = 0.6 + 0.4 * sin(t * 5.0 + fi * 1.5);
        // peak = 0.003/0.0004 = 7.5, x 40 x avg_pulse(0.6) �?180 �?Reinhard OK
        float glow = 0.003 / (dist * dist + 0.0004) * pulse;

        float hue = fract(fi / float(NUM_RING) + t * 0.5);
        vec3 rCol = hsv2rgb(vec3(hue, 0.6, 1.0));
        col += rCol * glow;
    }

    col = col / (1.0 + col);
    col = pow(col, vec3(0.9));
    fragColor = vec4(col, 1.0);
}
```

## Performance & Composition

**Performance**:
- Particle count is the biggest performance lever; use early exit `if (dist > threshold) continue;` for optimization
- Frame feedback trails (`prev * 0.95 + current`) can achieve high visual density with fewer particles
- N-body O(N²) interaction: reduce to O(1) neighbor queries using spatial grid partitioning or Voronoi tracking
- High-speed particles use sub-frame stepping to eliminate trajectory gaps
- Velocity/acceleration need clamp to prevent numerical explosion; Verlet is more stable than Euler
-

**Composition**:
- **Raymarching**: sample particle density during march steps, or particles in separate Buffer then composited
- **Noise / Flow Field**: use noise gradients to drive particle velocity, producing organic flow effects
- **Post-Processing**: Bloom (Gaussian blur overlay), chromatic aberration, Reinhard tone mapping
- **SDF shapes**: rotate local coordinates based on velocity direction to render fish/droplet specific shapes
- **Voronoi acceleration**: large-scale particles use Voronoi tracking, reducing rendering and physics queries from O(N) to O(1)

## Further Reading

Full step-by-step tutorial, mathematical derivations, and advanced usage in [reference](../reference/particle-system.md)
