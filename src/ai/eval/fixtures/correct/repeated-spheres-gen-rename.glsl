#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Scene: one sphere, repeated across the floor every 2 units
float sceneSDF(vec3 p) {
    // Fold x and z into one cell, from -1 to 1 around the sphere
    vec3 cell = p;
    cell.xz = mod(p.xz + 1.0, 2.0) - 1.0;
    float sphere = length(cell - vec3(0.0, 0.5, 0.0)) - 0.4;
    return min(sphere, p.y);
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

    // Camera looks from (0, 4, 5) at (0, 0, 0)
    vec3 eye = vec3(0.0, 4.0, 5.0);
    vec3 fwd = normalize(vec3(0.0) - eye);
    vec3 right = normalize(cross(fwd, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, fwd);
    vec3 dir = normalize(uv.x * right + uv.y * up + 2.0 * fwd);

    float t = 0.0;
    bool found = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = eye + dir * t;
        float d = sceneSDF(p);
        if (d < 0.001) {
            found = true;
            break;
        }
        t += d;
        if (t > 40.0) break;
    }

    vec3 color = vec3(0.04, 0.05, 0.09);
    if (found) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(0.4, 1.0, 0.3));
        float diff = max(dot(n, l), 0.0);

        vec3 base = p.y < 0.002 ? vec3(0.18, 0.26, 0.34) : vec3(0.93, 0.88, 0.78);
        color = base * (0.15 + 0.85 * diff);
    }
    fragColor = vec4(color, 1.0);
}
