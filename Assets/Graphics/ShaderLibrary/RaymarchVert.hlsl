#pragma once

#include "./RaymarchAttributes.hlsl"
#include "./RaymarchVaryings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

varyings raymarch_vert(const attributes input)
{
    varyings o;
    const VertexPositionInputs vpi = GetVertexPositionInputs(input.vertex.xyz);
    o.vertex = vpi.positionCS;
    o.ro = GetCameraPositionWS();
    o.hit_pos = vpi.positionWS;
    return o;
}
