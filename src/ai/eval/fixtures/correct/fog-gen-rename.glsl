#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Scene: six spheres going away from the camera, each one farther than the last
float sceneSDF(vec3 p) {
    float d = length(p - vec3(-1.3, -0.4, 0.0)) - 0.6;
    d = min(d, length(p - vec3(1.8, 0.3, -3.0)) - 0.6);
    d = min(d, length(p - vec3(-2.6, 0.6, -6.0)) - 0.6);
    d = min(d, length(p - vec3(3.2, -0.3, -9.0)) - 0.6);
    d = min(d, length(p - vec3(-3.8, 0.2, -12.0)) - 0.6);
    d = min(d, length(p - vec3(0.0, 0.0, -15.0)) - 0.8);
    return d;
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
    vec3 origin = vec3(0.0, 0.0, 3.0);
    vec3 dir = normalize(vec3(uv, -1.0));

    float dist = 0.0;
    bool found = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = origin + dir * dist;
        float d = sceneSDF(p);
        if (d < 0.001) {
            found = true;
            break;
        }
        dist += d;
        if (dist > 40.0) break;
    }

    // Misses are the fog col, so the far spheres fade into the background
    vec3 haze = vec3(0.75, 0.80, 0.86);
    vec3 col = haze;
    if (found) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(0.5, 1.0, 0.6));
        float lambert = max(dot(n, l), 0.0);
        col = vec3(0.85, 0.30, 0.22) * (0.2 + 0.8 * lambert);

        // The farther the found, the more of the fog col replaces the surface
        col = mix(col, haze, 1.0 - exp(-0.15 * dist));
    }
    fragColor = vec4(col, 1.0);
}
