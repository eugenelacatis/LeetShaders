#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float roundBox(vec2 p, vec2 halfSize, float radius) {
  vec2 q = abs(p) - halfSize + radius;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = roundBox(uv, vec2(0.55, 0.35), 0.15);
  float mask = 1.0 - smoothstep(-0.01, 0.01, abs(d) - 0.04);
  fragColor = vec4(mix(vec3(0.05, 0.07, 0.15), vec3(1.0, 0.8, 0.2), mask), 1.0);
}
