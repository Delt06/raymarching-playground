#ifndef RAYMARCH_ATTRIBUTES
#define RAYMARCH_ATTRIBUTES

struct varyings
{
    float4 vertex : SV_POSITION;
    float3 ro : TEXCOORD0;
    float3 hit_pos : TEXCOORD1;
};

#endif
