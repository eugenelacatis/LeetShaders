#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  fragColor = vec4(mix(vec3(0.0), vec3(0.0, 1.0, 1.0), uv.x), 1.0);
}
