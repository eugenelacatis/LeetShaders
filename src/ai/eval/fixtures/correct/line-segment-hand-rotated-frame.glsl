#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec2 DIR = vec2(0.894427, 0.447214);
const float HALF_LEN = 0.670820;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float along = dot(uv, DIR);
  float across = dot(uv, vec2(-DIR.y, DIR.x));
  float d = length(vec2(max(abs(along) - HALF_LEN, 0.0), across)) - 0.08;
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
