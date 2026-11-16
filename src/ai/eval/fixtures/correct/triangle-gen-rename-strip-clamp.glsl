#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 nA = vec2(0.0, -1.0);
    vec2 nB = vec2(0.866025, 0.5);
    vec2 nC = vec2(-0.866025, 0.5);
    float d = max(dot(p, nA), max(dot(p, nB), dot(p, nC))) - 0.4;

    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
