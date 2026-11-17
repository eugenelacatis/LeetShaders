#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance and angle around the center, angle turned into 0 to 1 turns
    float r = length(uv);
    float turns = atan(uv.y, uv.x) / 6.2831853;

    // Rings are fract(r * 3). Subtracting the angle slides each ring around, so they join into one spiral
    float v = r * 3.0 - turns;
    float band = smoothstep(0.24, 0.26, abs(fract(v) - 0.5));

    vec3 plum = vec3(0.2, 0.05, 0.3);
    vec3 pink = vec3(1.0, 0.45, 0.7);

    fragColor = vec4(mix(plum, pink, band) * vec3(1.0, 0.98, 0.96), 1.0);
}
