#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sphereA(vec3 p) {
    return length(p - vec3(-0.9, 0.6, 0.0)) - 0.6;
}

float sphereB(vec3 p) {
    return length(p - vec3(0.9, 0.45, -0.8)) - 0.45;
}

float sceneSDF(vec3 p) {
    return min(min(sphereA(p), sphereB(p)), p.y);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

const vec3 SKY = vec3(0.55, 0.70, 0.90);
const vec3 LIGHT = vec3(0.4, 0.8, 0.5);

vec3 shade(vec3 p, vec3 n) {
    float diff = max(dot(n, normalize(LIGHT)), 0.0);
    vec3 albedo = vec3(0.10, 0.12, 0.16);
    if (sphereA(p) < 0.002) albedo = vec3(0.90, 0.30, 0.55);
    else if (sphereB(p) < 0.002) albedo = vec3(0.95, 0.80, 0.25);
    return albedo * (0.2 + 0.8 * diff);
}

float march(vec3 eye, vec3 dir, int steps, float maxT) {
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        if (i >= steps) break;
        float d = sceneSDF(eye + dir * t);
        if (d < 0.001) return t;
        t += d;
        if (t > maxT) break;
    }
    return -1.0;
}

void shade() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec3 eye = vec3(0.0, 3.2, 4.5);
    vec3 fwd = normalize(vec3(0.0) - eye);
    vec3 right = normalize(cross(fwd, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, fwd);
    vec3 dir = normalize(uv.x * right + uv.y * up + 2.0 * fwd);

    vec3 color = SKY;
    float t = march(eye, dir, 64, 40.0);
    if (t > 0.0) {
        vec3 p = eye + dir * t;
        vec3 n = getNormal(p);
        color = shade(p, n);

        if (p.y < 0.002) {
            vec3 bounceDir = reflect(dir, n);
            vec3 bounceFrom = p + n * 0.01;
            float bounceT = march(bounceFrom, bounceDir, 32, 20.0);
            vec3 mirrored = SKY;
            if (bounceT > 0.0) {
                vec3 bounceHit = bounceFrom + bounceDir * bounceT;
                mirrored = shade(bounceHit, getNormal(bounceHit));
            }
            color = mix(color, mirrored, 0.5);
        }
    }
    fragColor = vec4(color, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
