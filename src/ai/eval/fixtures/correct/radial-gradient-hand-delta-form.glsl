#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float s = min(u_resolution.x, u_resolution.y);
  vec2 q = (gl_FragCoord.xy * 2.0 - u_resolution) / s;
  vec3 delta = vec3(0.2, 0.0, 0.4) - vec3(1.0);
  fragColor = vec4(vec3(1.0) + delta * smoothstep(0.0, 1.2, length(q)), 1.0);
}
