#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sdRing(float r, float radius, float halfWidth) {
  return abs(r - radius) - halfWidth;
}

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  float r = sqrt(dot(p, p));
  float d = min(sdRing(r, 0.45, 0.04), sdRing(r, 0.75, 0.04));
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
