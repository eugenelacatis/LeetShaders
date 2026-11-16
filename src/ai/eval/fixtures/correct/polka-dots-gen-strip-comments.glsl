#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 cell = fract(uv * 2.0) - 0.5;

    float d = length(cell) - 0.3;
    float mask = 1.0 - smoothstep(-0.02, 0.02, d);

    vec3 cream = vec3(0.96, 0.92, 0.82);
    vec3 coral = vec3(0.95, 0.4, 0.35);

    fragColor = vec4(mix(cream, coral, mask), 1.0);
}
