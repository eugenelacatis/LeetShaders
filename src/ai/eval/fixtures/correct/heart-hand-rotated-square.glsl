#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = vec2(abs(uv.x), uv.y + 0.06);
  vec2 r = vec2(p.x + p.y, p.y - p.x) * 0.70710678;
  float square = max(abs(r.x), abs(r.y)) - 0.4;
  float lobe = distance(p, vec2(0.283, 0.283)) - 0.4;
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, min(square, lobe))), 1.0);
}
