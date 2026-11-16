#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to the body (radius 0.6) and to the hole (radius 0.4 at x = 0.4)
    float body = length(p) - 0.6;
    float hole = length(p - vec2(0.4, 0.0)) - 0.4;

    // Subtraction: negating the hole turns its inside into outside, then max() keeps only the body part outside it
    float dist = max(body, -hole);

    // Inside the shape (dist < 0) is white, outside is black
    float inside = 1.0 - smoothstep(-0.01, 0.01, dist);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
}
