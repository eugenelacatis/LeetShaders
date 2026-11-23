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

float fill(float d) {
    return 1.0 - smoothstep(-0.01, 0.01, d);
}

vec3 strand(vec3 col, float d, vec3 ropeColor) {
    col = mix(col, vec3(0.03, 0.06, 0.07), fill(d - 0.15));
    return mix(col, ropeColor, fill(d - 0.10));
}

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 p = st * 2.5;
    ivec2 cell = ivec2(floor(p));
    vec2 local = fract(p) - 0.5;

    float band = fract((p.x + p.y) * 0.25 - u_time / 12.0);
    float gloss = 1.0 - smoothstep(0.0, 0.12, abs(band - 0.5));
    vec3 ropeColor = mix(vec3(0.85, 0.62, 0.25), vec3(1.0, 0.92, 0.70), gloss);

    vec3 col = vec3(0.05, 0.20, 0.22);

    uint tile = pcg(pcg(uint(cell.x)) + uint(cell.y)) % 3u;

    if (tile == 2u) {

        float across = abs(local.y);
        float upDown = abs(local.x);
        bool acrossOnTop = ((cell.x + cell.y) & 1) == 0;
        float under = acrossOnTop ? upDown : across;
        float over = acrossOnTop ? across : upDown;
        col = strand(col, under, ropeColor);
        col = strand(col, over, ropeColor);
    } else {

        vec2 c = (tile == 0u) ? vec2(0.5, 0.5) : vec2(0.5, -0.5);
        float d = min(abs(length(local - c) - 0.5), abs(length(local + c) - 0.5));
        col = strand(col, d, ropeColor);
    }

    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
