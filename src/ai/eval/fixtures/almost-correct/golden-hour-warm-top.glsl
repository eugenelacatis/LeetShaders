#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    vec3 bottom = vec3(0.98, 0.45, 0.1);
    vec3 middle = vec3(0.95, 0.75, 0.35);
    vec3 top = vec3(0.28, 0.3, 0.57);

    // Two blends stacked: bottom to middle over the lower half, middle to top over the upper half
    vec3 color = mix(bottom, middle, smoothstep(0.0, 0.5, uv.y));
    color = mix(color, top, smoothstep(0.5, 1.0, uv.y));

    fragColor = vec4(color, 1.0);
}
