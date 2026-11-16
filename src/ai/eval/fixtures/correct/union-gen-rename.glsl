#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to each circle: radius 0.4, centers at (-0.3, 0) and (0.3, 0)
    float left = length(p - vec2(-0.3, 0.0)) - 0.4;
    float right = length(p - vec2(0.3, 0.0)) - 0.4;

    // Union: a point is inside if it is inside either circle, so keep the smaller distance
    float dist = min(left, right);

    // Inside the shape (dist < 0) is white, outside is black
    float inside = 1.0 - smoothstep(-0.01, 0.01, dist);

    fragColor = vec4(vec3(inside), 1.0);
}
