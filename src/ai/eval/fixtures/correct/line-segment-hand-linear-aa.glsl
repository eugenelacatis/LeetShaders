#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 a = vec2(-0.6, -0.3);
  vec2 b = vec2(0.6, 0.3);
  vec2 pa = uv - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float d = length(pa - ba * h) - 0.08;
  float k = clamp(0.5 - d / 0.02, 0.0, 1.0);
  fragColor = vec4(k, k, k, 1.0);
}
