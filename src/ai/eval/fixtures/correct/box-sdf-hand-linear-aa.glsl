#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

float sdRoundedBox(vec2 p, vec2 b, float r) {
  vec2 d = abs(p) - b + r;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void main() {
  vec2 uv = (gl_FragCoord.xy / u_resolution) * 2.0 - 1.0;
  float d = sdRoundedBox(uv, vec2(0.5, 0.3), 0.08);
  float a = clamp(0.5 - d / 0.01, 0.0, 1.0);
  fragColor = vec4(a, a, a, 1.0);
}
