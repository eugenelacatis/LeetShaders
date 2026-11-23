#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// PCG hash: integer math only, so every GPU returns the same bits
uint pcg(uint value) {
    uint state = value * 747796405u + 2891336453u;
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

// fBm: 4 octaves, each at twice the frequency and half the amplitude
float fbm(vec2 p) {
    float total = 0.0;
    float weight = 0.5;
    for (int o = 0; o < 4; o++) {
        total += weight * noise(p);
        p *= 2.0;
        weight *= 0.5;
    }
    return total / 0.9375;
}

// Two fBm values read from far-apart spots, used as an offset
vec2 fbm2(vec2 p) {
    return vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
}

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    vec2 p = st * 1.2;

    // The offset: the innermost lookup circles with radius 0.3, once every 16 seconds
    float a = 6.28318 * u_time / 16.0;
    vec2 offset = 0.3 * vec2(cos(a), sin(a));

    // Domain warping: noise pushes where the next noise is read, twice over
    vec2 warp1 = fbm2(p + offset);
    vec2 warp2 = fbm2(p + 2.0 * warp1 + vec2(1.7, 9.2));
    float value = fbm(p + 2.0 * warp2);

    // Ink, then mid, then pale high as value rises
    vec3 deep = vec3(0.05, 0.03, 0.18);
    vec3 mid = vec3(0.75, 0.20, 0.45);
    vec3 high = vec3(1.00, 0.85, 0.55);
    vec3 col = mix(deep, mid, smoothstep(0.40, 0.55, value));
    col = mix(col, high, smoothstep(0.58, 0.72, value));

    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
}
