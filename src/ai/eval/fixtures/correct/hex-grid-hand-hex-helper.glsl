#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec2 hexLocal(vec2 p) {
  vec2 r = vec2(1.0, 1.7320508);
  vec2 h = r * 0.5;
  vec2 a = mod(p, r) - h;
  vec2 b = mod(p - h, r) - h;
  return dot(a, a) < dot(b, b) ? a : b;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 gv = hexLocal(uv * 3.0);
  float edge = 0.5 - max(dot(abs(gv), normalize(vec2(1.0, 1.7320508))), abs(gv.x));
  float line = 1.0 - smoothstep(0.02, 0.04, edge);
  fragColor = vec4(mix(vec3(0.05, 0.2, 0.25), vec3(0.4, 0.95, 0.9), line), 1.0);
}
