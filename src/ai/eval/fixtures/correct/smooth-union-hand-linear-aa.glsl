#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d1 = length(uv + vec2(0.35, 0.0)) - 0.35;
  float d2 = length(uv - vec2(0.35, 0.0)) - 0.35;
  float h = max(0.3 - abs(d1 - d2), 0.0) / 0.3;
  float d = min(d1, d2) - h * h * 0.075;
  float c = clamp(0.5 - d / 0.02, 0.0, 1.0);
  fragColor = vec4(c, c, c, 1.0);
}
