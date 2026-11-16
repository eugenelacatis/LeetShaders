#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float d = distance(gl_FragCoord.xy / u_resolution, vec2(0.5));
  float v = 1.0 - smoothstep(0.25, 0.75, d);
  fragColor = vec4(vec3(0.95, 0.85, 0.6) * v, 1.0);
}
