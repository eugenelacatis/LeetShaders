#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float cellPx = min(u_resolution.x, u_resolution.y) * 0.25;
  vec2 cell = fract((gl_FragCoord.xy - 0.5 * u_resolution) / cellPx) - 0.5;
  float mask = 1.0 - smoothstep(-0.02, 0.02, length(cell) - 0.3);
  fragColor = vec4(mix(vec3(0.96, 0.92, 0.82), vec3(0.95, 0.4, 0.35), mask), 1.0);
}
