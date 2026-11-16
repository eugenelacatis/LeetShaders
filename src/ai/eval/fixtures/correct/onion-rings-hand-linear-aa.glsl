#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = abs(abs(length(uv) - 0.6) - 0.15) - 0.04;
  float k = clamp(0.5 - d / 0.02, 0.0, 1.0);
  fragColor = vec4(k, k, k, 1.0);
}
