#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    

    vec2 cell = floor(st * 8.0);
    

    float parity = mod(cell.x + cell.y, 2.0);
    

    vec3 col = vec3(parity);
    
    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
