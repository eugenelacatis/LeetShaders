#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Five-pointed star, one point up. Tips at radius 0.8, inner corners at 0.32.
    float outer = 0.8;
    float inner = 0.32;
    float sector = 6.2831853 / 5.0;

    // Fold the plane into one half-point: angle 0 is a tip, angle sector/2 an inner corner
    float theta = atan(p.x, p.y);
    theta = abs(mod(theta + sector * 0.5, sector) - sector * 0.5);
    vec2 folded = length(p) * vec2(sin(theta), cos(theta));

    // Distance to the edge from the tip A to the inner corner B, signed by which side folded is on
    vec2 A = vec2(0.0, outer);
    vec2 B = inner * vec2(sin(sector * 0.5), cos(sector * 0.5));
    vec2 ap = folded - A;
    vec2 ab = B - A;
    float h = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    float side = sign(ap.y * ab.x - ap.x * ab.y);
    float d = length(ap - ab * h) * side;

    // Inside the shape (d < 0) is white, outside is black
    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
}
