#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 MORTAR = vec3(0.85, 0.82, 0.75);
const vec3 RED = vec3(0.7, 0.28, 0.2);

float brickMask(vec2 p) {
  p.x += 0.5 * mod(floor(p.y), 2.0);
  vec2 f = fract(p);
  return smoothstep(0.04, 0.06, f.x) * smoothstep(0.08, 0.1, f.y);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  fragColor = vec4(mix(MORTAR, RED, brickMask(uv * vec2(2.0, 4.0))), 1.0);
}
