#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

const float TAU = 6.28318530717958;

vec3 hsv2rgb(float h, float s, float v) {
  vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  return v * mix(vec3(1.0), rgb, s);
}

void main() {
  vec2 uv = (gl_FragCoord.xy / u_resolution) * 2.0 - 1.0;
  float hue = mod(atan(-uv.y, -uv.x) / TAU, 1.0);
  float r = length(uv);
  fragColor = vec4(hsv2rgb(hue, r, 1.0) * step(r, 0.9), 1.0);
}
