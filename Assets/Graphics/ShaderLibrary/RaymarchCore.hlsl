#pragma once

#ifndef MAX_STEPS
#define MAX_STEPS 100
#endif

#ifndef MAX_DIST
#define MAX_DIST 100.
#endif

#ifndef SURF_DISTANCE
#define SURF_DISTANCE 1e-3
#endif

#ifndef GET_DIST
#define GET_DIST get_dist_fallback
#endif

#include "./RaymarchSdf.hlsl"

float get_dist_fallback(const float3 p)
{
    return sphere_sdf(p, 0, 0.5);
}


float ray_march(const float3 ro, const float3 rd)
{
    float d_o = 0;

    for (int i = 0; i < MAX_STEPS; i++)
    {
        const float3 p = ro + rd * d_o;
        const float d_s = GET_DIST(p);
        d_o += d_s;
        if (d_s < SURF_DISTANCE || d_o > MAX_DIST)
            break;
    }

    return d_o;
}

float3 get_normal(const float3 p)
{
    const float2 eps = float2(1e-2, 0);
    const float3 n = GET_DIST(p) - float3(
        GET_DIST(p - eps.xyy),
        GET_DIST(p - eps.yxy),
        GET_DIST(p - eps.yyx)
    );
    return normalize(n);
}

#define RAY_MARCH_DISCARD(ro, hit_pos) const float3 rd = normalize(hit_pos - ro); const float d = ray_march(ro, rd);\
if (d >= MAX_DIST)\
{\
    discard;\
}\
const float3 p = ro + rd * d;
