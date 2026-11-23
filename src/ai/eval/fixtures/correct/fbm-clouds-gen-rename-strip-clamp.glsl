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
    float total = 0.0;
    float weight = 0.5;
    for (int octave = 0; octave < 5; octave++) {
        total += weight * noise(p);
        p *= 2.0;
        weight *= 0.5;
    }

    return total / 0.96875;
}

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float density = fbm(st * 2.0);

    vec3 blue = vec3(0.25, 0.50, 0.90);
    vec3 white = vec3(1.0);
    fragColor = vec4(mix(blue, white, smoothstep(0.35, 0.75, density)), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
