#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance and angle around the center, angle turned into 0 to 1 angle
    float radius = length(st);
    float angle = atan(st.y, st.x) / 6.2831853;

    // Rings are fract(radius * 3). Subtracting the angle slides each ring around, so they join into one spiral
    float phase = radius * 3.0 - angle;
    float arm = smoothstep(0.24, 0.26, abs(fract(phase) - 0.5));

    vec3 dark = vec3(0.2, 0.05, 0.3);
    vec3 light = vec3(1.0, 0.45, 0.7);

    fragColor = vec4(mix(dark, light, arm), 1.0);
}

void main() {
  shade();
}
