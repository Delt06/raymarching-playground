#pragma once

struct varyings
{
    float4 vertex : SV_POSITION;
    float3 ro : TEXCOORD0;
    float3 hit_pos : TEXCOORD1;
};
