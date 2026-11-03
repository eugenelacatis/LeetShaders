#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

float sdRoundedBox(vec2 p, vec2 b, float r) {
  vec2 d = abs(p) - b + r;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void shade() {

  vec2 q = (gl_FragCoord.xy / u_resolution) * 2.0 - 1.0;

  float d = sdRoundedBox(q, vec2(0.5, 0.3), 0.08);

  float inside = smoothstep(0.005, -0.005, d);

  fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
