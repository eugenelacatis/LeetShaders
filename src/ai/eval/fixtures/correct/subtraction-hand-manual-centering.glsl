#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 b = p - vec2(0.4, 0.0);
  float d = max(sqrt(dot(p, p)) - 0.6, 0.4 - sqrt(dot(b, b)));
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
