#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 BG = vec3(0.0);
const vec3 FG = vec3(1.0);

void main() {
  float s = min(u_resolution.x, u_resolution.y);
  vec2 q = (2.0 * gl_FragCoord.xy - u_resolution) / s;
  float edge = smoothstep(-0.01, 0.01, length(q) - 0.5);
  fragColor = vec4(mix(FG, BG, edge), 1.0);
}
