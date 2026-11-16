#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 SUN = vec3(0.98, 0.45, 0.1);
const vec3 GLOW = vec3(0.95, 0.75, 0.35);
const vec3 DUSK = vec3(0.25, 0.3, 0.6);

vec3 sky(float y) {
  vec3 c = mix(SUN, GLOW, smoothstep(0.0, 0.5, y));
  return mix(c, DUSK, smoothstep(0.5, 1.0, y));
}

void main() {
  fragColor = vec4(sky(gl_FragCoord.y / u_resolution.y), 1.0);
}
