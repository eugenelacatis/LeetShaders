#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float ease(float a, float b, float x) {
  float k = clamp((x - a) / (b - a), 0.0, 1.0);
  return k * k * (3.0 - 2.0 * k);
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  vec3 col = mix(vec3(0.98, 0.45, 0.1), vec3(0.95, 0.75, 0.35), ease(0.0, 0.5, uv.y));
  col = mix(col, vec3(0.25, 0.3, 0.6), ease(0.5, 1.0, uv.y));
  fragColor = vec4(col, 1.0);
}
