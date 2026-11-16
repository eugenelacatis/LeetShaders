#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    vec3 low = vec3(0.98, 0.45, 0.1);
    vec3 mid = vec3(0.95, 0.75, 0.35);
    vec3 high = vec3(0.25, 0.3, 0.6);

    // Two blends stacked: low to mid over the lower half, mid to high over the upper half
    vec3 col = mix(low, mid, smoothstep(0.0, 0.5, st.y));
    col = mix(col, high, smoothstep(0.5, 1.0, st.y));

    fragColor = vec4(col, 1.0);
}
