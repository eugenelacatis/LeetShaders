#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Hex cells need two overlapping rectangular grids, one shifted by half a cell
    vec2 q = st * 3.0;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(q, r) - h;
    vec2 b = mod(q - h, r) - h;

    // Take whichever grid center is closer. local is the position inside that hexagon
    vec2 local = dot(a, a) < dot(b, b) ? a : b;

    // Distance from local to the nearest hexagon dist: 0.5 at the center, 0 on an dist
    float dist = 0.5 - max(dot(abs(local), normalize(vec2(1.0, 1.7320508))), abs(local.x));

    float outline = 1.0 - smoothstep(0.02, 0.04, dist);

    vec3 deep = vec3(0.05, 0.2, 0.25);
    vec3 glow = vec3(0.4, 0.95, 0.9);

    fragColor = vec4(mix(deep, glow, outline), 1.0);
}
