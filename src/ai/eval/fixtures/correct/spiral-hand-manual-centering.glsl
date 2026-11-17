#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float turns = atan(p.y, p.x) / 6.2831853;
  float v = length(p) * 3.0 - turns;
  float m = smoothstep(0.24, 0.26, abs(fract(v) - 0.5));
  vec3 plum = vec3(0.2, 0.05, 0.3);
  fragColor = vec4(plum + (vec3(1.0, 0.45, 0.7) - plum) * m, 1.0);
}
