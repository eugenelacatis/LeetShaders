#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Polynomial smooth minimum: like min(a, b), but the two shapes melt together
// over a blend width k instead of meeting at a sharp crease
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// Scene: three spheres blended into one blob
float sceneSDF(vec3 p) {
    float a = length(p - vec3(-0.8, -0.2, 0.0)) - 0.8;
    float b = length(p - vec3(1.2, -0.15, 0.0)) - 0.7;
    float c = length(p - vec3(0.0, 0.7, 0.1)) - 0.6;
    return smin(smin(a, b, 0.6), c, 0.6);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Ray origin and direction
    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    float t = 0.0;
    bool hit = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = ro + rd * t;
        float d = sceneSDF(p);
        if (d < 0.001) {
            hit = true;
            break;
        }
        t += d;
        if (t > 10.0) break;
    }

    vec3 color = vec3(0.07, 0.13, 0.16);
    if (hit) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(-0.5, 0.8, 0.7));
        float diff = max(dot(n, l), 0.0);
        color = vec3(0.95, 0.45, 0.40) * (0.12 + 0.88 * diff);
    }
    fragColor = vec4(color, 1.0);
}
