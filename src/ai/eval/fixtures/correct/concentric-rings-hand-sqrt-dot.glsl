#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float r = sqrt(dot(uv, uv)) * 4.0;
  float band = smoothstep(0.24, 0.26, abs(r - floor(r) - 0.5));
  vec3 indigo = vec3(0.15, 0.1, 0.45);
  vec3 peach = vec3(1.0, 0.8, 0.65);
  fragColor = vec4(indigo * (1.0 - band) + peach * band, 1.0);
}
