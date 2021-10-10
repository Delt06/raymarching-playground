#pragma once

float glsl_mod(const float x, const float y)
{
    return x - y * floor(x / y);
}

#define GLSL_MOD(x, y) ((x) - (y) * floor((x) / (y)))
#define REPEAT(x, y) GLSL_MOD((x) + (y) * 0.5, (y)) - (y) * 0.5

float length_generic(float3 v, float p)
{
    v = pow(abs(v), p);
    return pow(v.x + v.y + v.z, 1 / p);
}

float length2(float3 p)
{
    p = p * p;
    return sqrt(p.x + p.y + p.z);
}

float length6(float3 p)
{
    p = p * p * p;
    p = p * p;
    return pow(p.x + p.y + p.z, 1.0 / 6.0);
}

float length8(float3 p)
{
    p = p * p;
    p = p * p;
    p = p * p;
    return pow(p.x + p.y + p.z, 1.0 / 8.0);
}

float sphere_sdf(const float3 p, const float3 o, const float r)
{
    return length(p - o) - r;
}

float ellipsoid_sdf(float3 p, const float3 o, const float3 r)
{
    p -= o;
    const float k0 = length(p / r);
    const float k1 = length((p / (r * r)));
    return k0 * (k0 - 1.0) / k1;
}

float ellipsoid_sdf(float3 p, const float3x3 ellipsoid)
{
    return ellipsoid_sdf(p, ellipsoid._m00_m01_m02, ellipsoid._m10_m11_m12);
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

float union_sdf(const float d1, const float d2) { return min(d1, d2); }

float subtraction_sdf(const float d1, const float d2) { return max(-d1, d2); }

float intersection_sdf(const float d1, const float d2) { return max(d1, d2); }

float capsule_sdf(const float3 p, const float3 a, const float3 b, const float r)
{
    const float3 pa = p - a;
    const float3 ba = b - a;
    const float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

#define SEGMENT_SDF(p, name) capsule_sdf(p, name##_a_r.xyz, name##_b, name##_a_r.w)

//https://timcoster.com/2020/02/13/raymarching-shader-pt3-smooth-blending-operators/
float smooth_intersect_sdf(const float dist_a, const float dist_b, const float k)
{
    const float h = clamp(0.5 - 0.5 * (dist_a - dist_b) / k, 0., 1.);
    return lerp(dist_a, dist_b, h) + k * h * (1. - h);
}

float smooth_union_sdf(const float dist_a, const float dist_b, const float k)
{
    const float h = clamp(0.5 + 0.5 * (dist_a - dist_b) / k, 0., 1.);
    return lerp(dist_a, dist_b, h) - k * h * (1. - h);
}

float smooth_difference_sdf(const float dist_a, const float dist_b, const float k)
{
    const float h = clamp(0.5 - 0.5 * (dist_b + dist_a) / k, 0., 1.);
    return lerp(dist_b, -dist_a, h) + k * h * (1. - h);
}
