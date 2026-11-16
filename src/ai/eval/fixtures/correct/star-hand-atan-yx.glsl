#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float sector = 6.2831853 / 5.0;
  float ang = 1.5707963 - atan(uv.y, uv.x);
  ang = abs(mod(ang + sector * 0.5, sector) - sector * 0.5);
  vec2 q = length(uv) * vec2(sin(ang), cos(ang));
  vec2 A = vec2(0.0, 0.8);
  vec2 B = 0.32 * vec2(sin(sector * 0.5), cos(sector * 0.5));
  vec2 pa = q - A;
  vec2 ba = B - A;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float d = length(pa - ba * h) * sign(pa.y * ba.x - pa.x * ba.y);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
