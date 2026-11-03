#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    
    // Polar coordinates
    float rho = length(p);
    float phi = atan(p.y, p.x);
    
    // 6-petaled flower pattern
    // The radius of the boundary varies with the angle
    float petal = abs(cos(phi * 3.0));
    
    // Step function to create phi sharp edge
    float inside = step(rho, petal * 0.8);
    
    // Magenta col for the flower
    vec3 col = inside * vec3(1.0, 0.0, 1.0);
    
    fragColor = vec4(col, 1.0);
}
