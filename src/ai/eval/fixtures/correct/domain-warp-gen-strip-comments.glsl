#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

float hash(ivec2 c) {
    uint h = pcg(pcg(uint(c.x)) + uint(c.y));
    return float(h >> 8) / 16777216.0;
}

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

float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    for (int o = 0; o < 4; o++) {
        sum += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return sum / 0.9375;
}

vec2 fbm2(vec2 p) {
    return vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
}

void main() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    vec2 p = uv * 1.2;

    float a = 6.28318 * u_time / 16.0;
    vec2 drift = 0.3 * vec2(cos(a), sin(a));

    vec2 q = fbm2(p + drift);
    vec2 r = fbm2(p + 2.0 * q + vec2(1.7, 9.2));
    float v = fbm(p + 2.0 * r);

    vec3 ink = vec3(0.05, 0.03, 0.18);
    vec3 magenta = vec3(0.75, 0.20, 0.45);
    vec3 gold = vec3(1.00, 0.85, 0.55);
    vec3 color = mix(ink, magenta, smoothstep(0.40, 0.55, v));
    color = mix(color, gold, smoothstep(0.58, 0.72, v));

    fragColor = vec4(color, 1.0);
}
