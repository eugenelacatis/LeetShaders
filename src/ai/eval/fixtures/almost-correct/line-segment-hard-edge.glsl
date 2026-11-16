#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Segment from a to b, drawn as a line with rounded ends 0.08 thick each side
    vec2 a = vec2(-0.6, -0.3);
    vec2 b = vec2(0.6, 0.3);

    // Project the point onto the segment, clamped to its ends
    vec2 pa = uv - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float d = length(pa - ba * h) - 0.08;

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - step(0.0, d);

    fragColor = vec4(vec3(mask), 1.0);
}
