#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

const float PI = 3.14159265358979;

vec3 wheelColor(vec2 p) {
  float h = atan(p.y, p.x) / (2.0 * PI) + 0.5;
  vec3 k = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  return mix(vec3(1.0), k, length(p));
}

void main() {
  vec2 p = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  if (length(p) > 0.9) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }
  fragColor = vec4(wheelColor(p), 1.0);
}
