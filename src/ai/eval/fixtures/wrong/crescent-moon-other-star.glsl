#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Five-pointed star, one point up. Tips at radius 0.8, inner corners at 0.32.
    float outer = 0.8;
    float inner = 0.32;
    float sector = 6.2831853 / 5.0;

    // Fold the plane into one half-point: angle 0 is a tip, angle sector/2 an inner corner
    float ang = atan(uv.x, uv.y);
    ang = abs(mod(ang + sector * 0.5, sector) - sector * 0.5);
    vec2 q = length(uv) * vec2(sin(ang), cos(ang));

    // Distance to the edge from the tip A to the inner corner B, signed by which side q is on
    vec2 A = vec2(0.0, outer);
    vec2 B = inner * vec2(sin(sector * 0.5), cos(sector * 0.5));
    vec2 pa = q - A;
    vec2 ba = B - A;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float side = sign(pa.y * ba.x - pa.x * ba.y);
    float d = length(pa - ba * h) * side;

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(mask), 1.0);
}
