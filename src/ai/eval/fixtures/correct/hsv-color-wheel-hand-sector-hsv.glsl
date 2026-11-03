#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

const float PI = 3.14159265358979;

vec3 hsvToRgb(float h, float s, float v) {
  float c = v * s;
  float hp = h * 6.0;
  float x = c * (1.0 - abs(mod(hp, 2.0) - 1.0));
  vec3 rgb;
  if (hp < 1.0)      rgb = vec3(c, x, 0.0);
  else if (hp < 2.0) rgb = vec3(x, c, 0.0);
  else if (hp < 3.0) rgb = vec3(0.0, c, x);
  else if (hp < 4.0) rgb = vec3(0.0, x, c);
  else if (hp < 5.0) rgb = vec3(x, 0.0, c);
  else               rgb = vec3(c, 0.0, x);
  return rgb + (v - c);
}

void main() {
  vec2 uv = (gl_FragCoord.xy / u_resolution) * 2.0 - 1.0;
  float r = length(uv);
  float h = atan(uv.y, uv.x) / (2.0 * PI) + 0.5;
  vec3 col = hsvToRgb(h, r, 1.0);
  fragColor = vec4(col * step(r, 0.9), 1.0);
}
