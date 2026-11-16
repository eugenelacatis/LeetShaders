#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = distance(fract(uv * 2.0), vec2(0.5)) - 0.3;
  float m = 1.0 - smoothstep(-0.02, 0.02, d);
  vec3 col = vec3(0.96, 0.92, 0.82) * (1.0 - m) + vec3(0.95, 0.4, 0.35) * m;
  fragColor = vec4(col, 1.0);
}
