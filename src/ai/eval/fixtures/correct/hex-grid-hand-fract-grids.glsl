#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv * 3.0;
  vec2 r = vec2(1.0, 1.7320508);
  vec2 h = r * 0.5;
  vec2 a = fract(p / r) * r - h;
  vec2 b = fract((p - h) / r) * r - h;
  vec2 gv = dot(a, a) < dot(b, b) ? a : b;
  float edge = 0.5 - max(dot(abs(gv), normalize(r)), abs(gv.x));
  fragColor = vec4(mix(vec3(0.05, 0.2, 0.25), vec3(0.4, 0.95, 0.9), 1.0 - smoothstep(0.02, 0.04, edge)), 1.0);
}
