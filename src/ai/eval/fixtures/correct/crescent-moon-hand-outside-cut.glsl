#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float inMoon = length(uv) - 0.65;
  float outCut = 0.55 - distance(uv, vec2(0.3, 0.12));
  float d = max(inMoon, outCut);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
