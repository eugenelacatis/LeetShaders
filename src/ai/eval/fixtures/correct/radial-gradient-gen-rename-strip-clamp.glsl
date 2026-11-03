#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    

    float r = length(p);
    

    vec3 col = mix(vec3(1.0), vec3(0.2, 0.0, 0.4), smoothstep(0.0, 1.2, r));
    
    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
