#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

const float PI = 3.14159265358979;

float channel(float h6, float offset) {
  return clamp(abs(mod(h6 + offset, 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main() {
  vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
  float s = length(uv);
  float h6 = (atan(uv.y, uv.x) / (2.0 * PI) + 0.5) * 6.0;
  vec3 pure = vec3(channel(h6, 0.0), channel(h6, 4.0), channel(h6, 2.0));
  vec3 col = (1.0 - s) + s * pure;
  fragColor = vec4(s <= 0.9 ? col : vec3(0.0), 1.0);
}
