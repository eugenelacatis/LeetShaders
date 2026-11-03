#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float t = clamp(length(uv) / 1.2, 0.0, 1.0);
  t = t * t * (3.0 - 2.0 * t);
  fragColor = vec4(mix(vec3(1.0), vec3(0.2, 0.0, 0.4), t), 1.0);
}
