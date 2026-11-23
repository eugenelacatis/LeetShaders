#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// PCG hash: integer math only, so every GPU returns the same bits
uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// One random number in [0, 1) per lattice corner
float hash(ivec2 c) {
    uint h = pcg(pcg(uint(c.x)) + uint(c.y));
    return float(h >> 8) / 16777216.0;
}

// @cell Value noise
// @numbers Corners are hash(i), hash(i + ivec2(1, 0)), hash(i + ivec2(0, 1)) and hash(i + ivec2(1, 1)), with i = ivec2(floor(p)). Blend them with u = f * f * (3.0 - 2.0 * f), where f = fract(p): across x first, then across y.
float noise(vec2 p) {
    ivec2 i = ivec2(floor(p));
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + ivec2(1, 0));
    float c = hash(i + ivec2(0, 1));
    float d = hash(i + ivec2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
// @end

// Turns each octave by about 37 degrees so the lattice lines don't stack up
const mat2 ROT = mat2(0.8, 0.6, -0.6, 0.8);

// @cell Terrain height
// @numbers 5 octaves. Start at p * 0.35 and amplitude 0.5. After each octave, p = ROT * p * 2.0 and the amplitude halves. Divide the sum by 0.96875, then square it and multiply by 2.2, so valleys flatten and peaks sharpen.
float terrain(vec2 p) {
    p *= 0.35;
    float sum = 0.0;
    float amp = 0.5;
    for (int o = 0; o < 5; o++) {
        sum += amp * noise(p);
        p = ROT * p * 2.0;
        amp *= 0.5;
    }
    float h = sum / 0.96875;
    return 2.2 * h * h;
}
// @end

// @cell Surface normal
// @numbers Central differences with e = 0.01: n = normalize(vec3(terrain(p.xz - (e, 0)) - terrain(p.xz + (e, 0)), 2.0 * e, terrain(p.xz - (0, e)) - terrain(p.xz + (0, e)))).
vec3 terrainNormal(vec3 p) {
    const float e = 0.01;
    return normalize(vec3(
        terrain(p.xz - vec2(e, 0.0)) - terrain(p.xz + vec2(e, 0.0)),
        2.0 * e,
        terrain(p.xz - vec2(0.0, e)) - terrain(p.xz + vec2(0.0, e))
    ));
}
// @end

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // The camera glides forward (toward -z) at 0.4 units a second, looking slightly down
    float z = -0.4 * u_time;
    vec3 ro = vec3(0.0, 2.6, z);
    vec3 ww = normalize(vec3(0.0, 1.7, z - 4.0) - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.6 * ww);

    vec3 sun = normalize(vec3(-0.6, 0.45, -0.65));

    // Sky: pale horizon to deep blue overhead, with a warm glow around the sun
    vec3 horizon = vec3(0.86, 0.80, 0.74);
    vec3 zenith = vec3(0.28, 0.46, 0.78);
    vec3 sky = mix(horizon, zenith, clamp(rd.y * 2.5, 0.0, 1.0));
    sky += vec3(1.0, 0.75, 0.45) * 0.35 * pow(max(dot(rd, sun), 0.0), 12.0);

    // March the height field: step a fraction of the height above the ground.
    // Only a ray that leaves the scene is a miss; one that runs out of steps
    // is grazing a ridge, so it counts as ground.
    float t = 0.2;
    bool hit = true;
    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * t;
        float h = p.y - terrain(p.xz);
        if (h < 0.002 * t) break;
        t += 0.45 * h;
        if (t > 30.0 || (p.y > 2.3 && rd.y > 0.0)) {
            hit = false;
            break;
        }
    }

    vec3 color = sky;
    if (hit) {
        vec3 p = ro + rd * t;
        vec3 n = terrainNormal(p);

        // Rock on steep slopes, grass on flat ground, snow on high flat ground
        vec3 albedo = vec3(0.42, 0.36, 0.30);
        albedo = mix(albedo, vec3(0.30, 0.42, 0.20), smoothstep(0.86, 0.94, n.y));
        float snow = smoothstep(0.75, 0.95, p.y) * smoothstep(0.55, 0.7, n.y);
        albedo = mix(albedo, vec3(0.95, 0.96, 1.0), snow);

        float diff = max(dot(n, sun), 0.0);
        float amb = 0.5 + 0.5 * n.y;
        color = albedo * (vec3(1.0, 0.92, 0.80) * 1.1 * diff + vec3(0.30, 0.38, 0.50) * amb);

        // Distance fog fades the far ridges into the horizon color
        color = mix(color, horizon, 1.0 - exp(-0.09 * t));
    }
    fragColor = vec4(color, 1.0);
}

void main() {
  shade();
  if (u_time != 0.0) fragColor = vec4(1.0 - fragColor.rgb, 1.0);
}
