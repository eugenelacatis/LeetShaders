#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float r = length(uv);
  float mask = (1.0 - smoothstep(0.66, 0.68, r)) * smoothstep(0.42, 0.44, r);
  fragColor = vec4(vec3(mask), 1.0);
}
