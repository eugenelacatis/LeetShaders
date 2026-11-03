#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float k = smoothstep(0.0, 1.2, sqrt(dot(p, p)));
  fragColor = vec4(vec3(1.0) * (1.0 - k) + vec3(0.2, 0.0, 0.4) * k, 1.0);
}
