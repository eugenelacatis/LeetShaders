#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

float roundBox(vec2 p, vec2 halfSize, float radius) {
  vec2 q = abs(p) - halfSize + radius;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void main() {
  vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
  float d = roundBox(uv, vec2(0.5, 0.3), 0.08);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.005, 0.005, d)), 1.0);
}
