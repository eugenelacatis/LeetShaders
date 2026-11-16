#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sdStar5(vec2 p, float outer, float inner) {
  const float SECTOR = 6.2831853 / 5.0;
  float a = abs(mod(atan(p.x, p.y) + SECTOR * 0.5, SECTOR) - SECTOR * 0.5);
  vec2 q = length(p) * vec2(sin(a), cos(a));
  vec2 tip = vec2(0.0, outer);
  vec2 corner = inner * vec2(sin(SECTOR * 0.5), cos(SECTOR * 0.5));
  vec2 e = corner - tip;
  vec2 w = q - tip;
  float h = clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
  float s = sign(w.y * e.x - w.x * e.y);
  return length(w - e * h) * s;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, sdStar5(uv, 0.8, 0.32))), 1.0);
}
