#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 INDIGO = vec3(0.15, 0.1, 0.45);
const vec3 PEACH = vec3(1.0, 0.8, 0.65);

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float t = abs(fract(4.0 * length(p)) - 0.5);
  float m = smoothstep(0.24, 0.26, t);
  fragColor = vec4(INDIGO + (PEACH - INDIGO) * m, 1.0);
}
