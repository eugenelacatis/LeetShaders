#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

const vec2 HALF = vec2(0.5, 0.3);
const float RADIUS = 0.08;

void main() {
  vec2 p = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  vec2 d = abs(p) - HALF + RADIUS;
  float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - RADIUS;
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.005, 0.005, dist)), 1.0);
}
