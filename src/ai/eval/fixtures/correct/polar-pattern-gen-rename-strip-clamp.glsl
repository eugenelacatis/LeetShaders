#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    

    float rho = length(p);
    float phi = atan(p.y, p.x);
    

    float petal = abs(cos(phi * 3.0));
    

    float inside = step(rho, petal * 0.8);
    

    vec3 col = inside * vec3(1.0, 0.0, 1.0);
    
    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
