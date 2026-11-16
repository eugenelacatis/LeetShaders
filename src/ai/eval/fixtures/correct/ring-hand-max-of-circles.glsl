#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float s = min(u_resolution.x, u_resolution.y);
  vec2 q = (2.0 * gl_FragCoord.xy - u_resolution) / s;
  float r = length(q);
  float d = max(r - 0.67, 0.43 - r);
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
