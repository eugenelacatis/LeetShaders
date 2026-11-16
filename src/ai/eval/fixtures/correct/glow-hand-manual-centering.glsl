#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float d = distance(p, vec2(0.0)) - 0.3;
  float glow = exp(-5.0 * max(d, 0.0)) * 0.9;
  vec3 col = vec3(0.02, 0.02, 0.08) + glow * vec3(1.0, 0.55, 0.15);
  col = mix(col, vec3(1.0), 1.0 - smoothstep(-0.01, 0.01, d));
  fragColor = vec4(col, 1.0);
}
