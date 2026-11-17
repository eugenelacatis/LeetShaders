#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 NIGHT = vec3(0.04, 0.05, 0.2);
const vec3 GOLD = vec3(1.0, 0.75, 0.2);

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  float sector = 1.0471976;
  float a = mod(atan(st.y, st.x), sector) - 0.5 * sector;
  a = abs(a);
  vec2 p = length(st) * vec2(cos(a), sin(a));
  float m = 1.0 - smoothstep(-0.01, 0.01, distance(p, vec2(0.55, 0.12)) - 0.14);
  fragColor = vec4(NIGHT + (GOLD - NIGHT) * m, 1.0);
}
