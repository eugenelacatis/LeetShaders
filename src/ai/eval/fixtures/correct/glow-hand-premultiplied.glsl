#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = length(uv) - 0.3;
  vec3 col = vec3(0.02, 0.02, 0.08) + vec3(0.9, 0.495, 0.135) * exp(-5.0 * max(d, 0.0));
  col = mix(col, vec3(1.0), 1.0 - smoothstep(-0.01, 0.01, d));
  fragColor = vec4(col, 1.0);
}
