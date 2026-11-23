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

float hash(ivec2 c) {
    uint h = pcg(pcg(uint(c.x)) + uint(c.y));
    return float(h >> 8) / 16777216.0;
}

// Value noise: smoothstep blend of the four lattice corners
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

// fBm: 5 octaves, each at twice the frequency and half the amplitude
float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    for (int o = 0; o < 5; o++) {
        sum += amp * noise(p);
        p *= 2.01;
        amp *= 0.5;
    }
    // The amplitudes add up to 0.96875, so divide to land back in [0, 1)
    return sum / 0.96875;
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float n = fbm(uv * 2.0);

    // Sky blue where the noise is low, white where it is high
    vec3 sky = vec3(0.25, 0.50, 0.90);
    vec3 cloud = vec3(1.0);
    fragColor = vec4(mix(sky, cloud, smoothstep(0.35, 0.75, n)), 1.0);
}
