#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to each circle: radius 0.35, centers at (-0.35, 0) and (0.35, 0)
    float left = length(p - vec2(-0.35, 0.0)) - 0.35;
    float right = length(p - vec2(0.35, 0.0)) - 0.35;

    // Polynomial smooth minimum, blend width 0.3. w is 0 far from the crease and 1 right on it
    float blend = 0.3;
    float w = max(blend - abs(left - right), 0.0) / blend;
    float d = min(left, right) - w * w * blend * 0.25;

    // Inside the shape (d < 0) is white, outside is black
    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}
