#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 CORE = vec3(1.0);
const vec3 EDGE = vec3(0.2, 0.0, 0.4);
const float FALLOFF = 1.2;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  fragColor = vec4(mix(CORE, EDGE, smoothstep(0.0, FALLOFF, length(uv))), 1.0);
}
