#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float d = -1e9;
  for (int i = 0; i < 2; i++) {
    vec2 c = vec2(i == 0 ? -0.25 : 0.25, 0.0);
    d = max(d, distance(p, c) - 0.55);
  }
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
