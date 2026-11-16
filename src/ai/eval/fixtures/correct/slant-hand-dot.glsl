#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float t = dot(uv, vec2(0.5));
  fragColor = vec4(mix(vec3(1.0, 0.6, 0.1), vec3(0.8, 0.1, 0.6), t), 1.0);
}
