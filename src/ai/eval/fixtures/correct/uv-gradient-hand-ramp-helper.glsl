#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec3 cyanRamp(float x) {
  float k = clamp(x, 0.0, 1.0);
  return vec3(0.0, k, k);
}

void main() {
  fragColor = vec4(cyanRamp(gl_FragCoord.x / u_resolution.x), 1.0);
}
