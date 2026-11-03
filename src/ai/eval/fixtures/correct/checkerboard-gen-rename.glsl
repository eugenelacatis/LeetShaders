#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    
    // Create 8x8 cell
    vec2 cell = floor(st * 8.0);
    
    // If the sum of coordinates is even, it's one col, otherwise another
    float parity = mod(cell.x + cell.y, 2.0);
    
    // 0.0 (black) or 1.0 (white)
    vec3 col = vec3(parity);
    
    fragColor = vec4(col, 1.0);
}
