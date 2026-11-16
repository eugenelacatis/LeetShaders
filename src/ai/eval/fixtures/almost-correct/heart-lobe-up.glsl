#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Shift the heart down a little so it sits in the middle, then mirror x so only one half is built
    vec2 p = uv + vec2(0.0, 0.06);
    p.x = abs(p.x);

    // A square turned 45 degrees: half-side 0.4, corners at distance 0.566
    float square = (p.x + abs(p.y)) / 1.41421356 - 0.4;

    // A circle of radius 0.4 on the upper right edge, centered at (0.283, 0.283)
    float lobe = length(p - vec2(0.283, 0.293)) - 0.4;

    // Union of the square and the lobe
    float d = min(square, lobe);

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(mask), 1.0);
}
