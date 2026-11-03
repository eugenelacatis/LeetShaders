#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    
    // Signed Distance Function for a circle of radius 0.5
    float dist = length(p) - 0.5;
    
    // Smoothstep for nice anti-aliased edges
    float inside = 1.0 - smoothstep(-0.01, 0.01, dist);
    
    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
}
