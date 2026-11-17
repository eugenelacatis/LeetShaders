#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 q = abs(uv) - vec2(0.4, 0.2);
  float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.15;
  float outer = 1.0 - smoothstep(-0.01, 0.01, d - 0.04);
  float inner = smoothstep(-0.01, 0.01, d + 0.04);
  fragColor = vec4(mix(vec3(0.05, 0.07, 0.15), vec3(1.0, 0.8, 0.2), outer * inner), 1.0);
}
