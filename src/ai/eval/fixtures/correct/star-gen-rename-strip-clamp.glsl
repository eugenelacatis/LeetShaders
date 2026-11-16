#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float outer = 0.8;
    float inner = 0.32;
    float sector = 6.2831853 / 5.0;

    float theta = atan(p.x, p.y);
    theta = abs(mod(theta + sector * 0.5, sector) - sector * 0.5);
    vec2 folded = length(p) * vec2(sin(theta), cos(theta));

    vec2 A = vec2(0.0, outer);
    vec2 B = inner * vec2(sin(sector * 0.5), cos(sector * 0.5));
    vec2 ap = folded - A;
    vec2 ab = B - A;
    float h = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    float side = sign(ap.y * ab.x - ap.x * ab.y);
    float d = length(ap - ab * h) * side;

    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
