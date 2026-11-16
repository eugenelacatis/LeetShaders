#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  // The farther circle always gives the larger distance.
  float d = length(vec2(abs(uv.x) + 0.25, uv.y)) - 0.55;
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
