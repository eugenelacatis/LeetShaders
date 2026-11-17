#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float rings(vec2 p) {
  return smoothstep(0.24, 0.26, abs(fract(length(p) * 4.0) - 0.5));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  fragColor = vec4(mix(vec3(0.15, 0.1, 0.45), vec3(1.0, 0.8, 0.65), rings(uv)), 1.0);
}
