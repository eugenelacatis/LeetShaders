#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float circleMask(vec2 p, float radius, float aa) {
  float d = length(p) - radius;
  float t = clamp((d + aa) / (2.0 * aa), 0.0, 1.0);
  return 1.0 - t * t * (3.0 - 2.0 * t);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  fragColor = vec4(vec3(circleMask(uv, 0.5, 0.01)), 1.0);
}
