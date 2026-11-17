#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 p = st * 3.0;
  vec2 r = vec2(1.0, 1.7320508);
  vec2 a = mod(p, r) - 0.5 * r;
  vec2 b = mod(p - 0.5 * r, r) - 0.5 * r;
  vec2 gv = a;
  if (dot(b, b) <= dot(a, a)) gv = b;
  vec2 g = abs(gv);
  float edge = 0.5 - max(dot(g, normalize(r)), g.x);
  float line = 1.0 - smoothstep(0.02, 0.04, edge);
  vec3 teal = vec3(0.05, 0.2, 0.25);
  fragColor = vec4(teal + (vec3(0.4, 0.95, 0.9) - teal) * line, 1.0);
}
