#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to the disc (radius 0.6) and to the bite (radius 0.4 at x = 0.4)
    float disc = length(uv) - 0.6;
    float bite = length(uv - vec2(0.4, 0.0)) - 0.4;

    // Subtraction: negating the bite turns its inside into outside, then max() keeps only the disc part outside it
    float d = max(disc, -bite);

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(mix(vec3(0.04), vec3(1.0), mask), 1.0);
}
