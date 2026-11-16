#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Four cells across. fract() gives every cell its own 0 to 1 coordinates, minus 0.5 centers them
    vec2 cell = fract(uv * 2.0) - 0.5;

    // Circle at the middle of every cell, radius 0.3 of the cell
    float d = length(cell) - 0.29;
    float mask = 1.0 - smoothstep(-0.02, 0.02, d);

    vec3 cream = vec3(0.96, 0.92, 0.82);
    vec3 coral = vec3(0.95, 0.4, 0.35);

    fragColor = vec4(mix(cream, coral, mask), 1.0);
}
