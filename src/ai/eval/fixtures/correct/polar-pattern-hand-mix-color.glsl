#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 MAGENTA = vec3(1.0, 0.0, 1.0);

void main() {
  float s = min(u_resolution.x, u_resolution.y);
  vec2 q = (gl_FragCoord.xy * 2.0 - u_resolution) / s;
  float boundary = 0.8 * abs(cos(atan(q.y, q.x) * 3.0));
  fragColor = vec4(mix(vec3(0.0), MAGENTA, step(length(q), boundary)), 1.0);
}
