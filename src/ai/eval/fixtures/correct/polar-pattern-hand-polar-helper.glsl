#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

float flower(vec2 polar, float petals, float size) {
  return step(polar.x, abs(cos(polar.y * petals * 0.5)) * size);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float m = flower(toPolar(uv), 6.0, 0.8);
  fragColor = vec4(m, 0.0, m, 1.0);
}
