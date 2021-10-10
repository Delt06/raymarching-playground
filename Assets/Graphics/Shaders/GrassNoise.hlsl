#pragma once

//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

float rand(const float n) { return frac(sin(n) * 43758.5453123); }

float rand(const float2 n)
{
    return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
}

float noise(const float p)
{
    const float fl = floor(p);
    const float fc = frac(p);
    return lerp(rand(fl), rand(fl + 1.0), fc);
}

float noise(const float2 n)
{
    const float2 d = float2(0.0, 1.0);
    const float2 b = floor(n);
    float2 f = smoothstep(0.0, 1.0, frac(n));
    return lerp(lerp(rand(b), rand(b + d.yx), f.x), lerp(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}
