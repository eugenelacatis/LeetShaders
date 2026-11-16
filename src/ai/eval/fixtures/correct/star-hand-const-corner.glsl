#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const float SECTOR = 1.2566371;
const vec2 TIP = vec2(0.0, 0.8);
const vec2 CORNER = vec2(0.188091, 0.258885);

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float a = atan(p.x, p.y);
  a = abs(mod(a + 0.5 * SECTOR, SECTOR) - 0.5 * SECTOR);
  vec2 q = length(p) * vec2(sin(a), cos(a));
  vec2 edge = CORNER - TIP;
  vec2 w = q - TIP;
  float h = clamp(dot(w, edge) / dot(edge, edge), 0.0, 1.0);
  float d = length(w - edge * h) * sign(w.y * edge.x - w.x * edge.y);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
