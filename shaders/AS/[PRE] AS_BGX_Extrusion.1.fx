#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime()

// Original Shadertoy Defines
#define SUBDIVIDE
#define SPARKLES
// #define GRAYSCALE // Uncomment for grayscale
#define FAR 20.0

// Global variables to pass hit information
static float objID;
static float2 gID;

// Standard 2D rotation formula.
float2x2 rot2(in float a) {
    float c = cos(a), s = sin(a);
    return float2x2(c, -s, s, c);
}

// IQ's vec2 to float hash.
float hash21(float2 p) {
    return frac(sin(dot(p, float2(27.609, 57.583))) * 43758.5453);
}

// Getting the video texture (ReShade BackBuffer).
float3 getTex(float2 p) { // p is svGID (world coordinates of block cell)

    // --- REVISED MAPPING LOGIC ---
    // Assume the primary visible area of blocks in world space (svGID)
    // is roughly within a square of 'world_view_span' units centered at origin.
    // We map this square area to the full [0,1]x[0,1] UV space of the backbuffer.
    float world_view_span = 4.0; // Example: visible world X/Y coords from -2.0 to +2.0
                                 // This acts like a "zoom" level for the backbuffer on the blocks.
                                 // Smaller value = more zoomed in on the backbuffer image.
    float2 uv_coords = p / world_view_span + 0.5;
    // This maps:
    // p.x from -world_view_span/2 to +world_view_span/2  maps to uv_coords.x from 0 to 1.
    // p.y from -world_view_span/2 to +world_view_span/2  maps to uv_coords.y from 0 to 1.

    // The default sampler for ReShade::BackBuffer is CLAMP_TO_EDGE.
    // So, if 'p' (svGID) goes beyond the range [-world_view_span/2, world_view_span/2], 
    // the UVs will effectively clamp to the [0,1] edge, sampling the edge pixels of the backbuffer.
    // This is usually desirable. If a repeating pattern is strictly needed for out-of-range svGIDs,
    // you could apply frac(uv_coords), but that might re-introduce tiling artifacts if not intended.

    // Use tex2Dlod to sample with an explicit LOD of 0.0
    float3 tx = tex2Dlod(ReShade::BackBuffer, float4(uv_coords, 0.0, 0.0)).xyz;
    return tx * tx; // Rough sRGB to linear conversion.
}


// Height map value
float hm(in float2 p) {
    return dot(getTex(p), float3(0.299, 0.587, 0.114));
}

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h) {
    float2 w = float2(sdf, abs(pz) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}

// IQ's unsigned box formula.
float sBoxS(in float2 p, in float2 b, in float sf) {
    return length(max(abs(p) - b + sf, 0.0)) - sf;
}

// Extruded block grid
float4 blocks(float3 q3) {
    const float scale = 1.0 / 16.0;
    const float2 l = float2(scale, scale);
    const float2 s = l * 2.0;

    float d = 1e5;
    float2 p_local, ip;
    float2 id_hit = float2(0,0);
    float2 cntr_offset;

    static const float2 ps4[4] = {
        float2(-l.x, l.y), l, -l, float2(l.x, -l.y)
    };
    float boxID_hit = 0.0;

    for (int i = 0; i < 4; i++) {
        cntr_offset = ps4[i] / 2.0;
        p_local = q3.xy - cntr_offset;
        ip = floor(p_local / s) + 0.5;
        p_local -= ip * s;
        float2 idi = ip * s + cntr_offset;
        float h = hm(idi);

#ifndef SUBDIVIDE
        h = floor(h * 15.999) / 15.0 * 0.15;
#endif

#ifdef SUBDIVIDE
        float4 h4_sub; 
        int sub_flag = 0;
        for (int j = 0; j < 4; j++) { 
            h4_sub[j] = hm(idi + ps4[j] / 4.0);
            if (abs(h4_sub[j] - h) > 1.0 / 15.0) sub_flag = 1;
        }

        h = floor(h * 15.999) / 15.0 * 0.15;
        h4_sub = floor(h4_sub * 15.999) / 15.0 * 0.15;

        if (sub_flag == 1) {
            float4 d4_sub_sdf, d4_sub_extruded; 
            for (int j = 0; j < 4; j++) { 
                d4_sub_sdf[j] = sBoxS(p_local - ps4[j] / 4.0, l / 4.0 - 0.05 * scale, 0.005);
                d4_sub_extruded[j] = opExtrusion(d4_sub_sdf[j], (q3.z + h4_sub[j]), h4_sub[j]);
                if (d4_sub_extruded[j] < d) {
                    d = d4_sub_extruded[j];
                    id_hit = idi + ps4[j] / 4.0;
                }
            }
        } else {
#endif
            float di2D = sBoxS(p_local, l / 2.0 - 0.05 * scale, 0.015);
            float di = opExtrusion(di2D, (q3.z + h), h);
            if (di < d) {
                d = di;
                id_hit = idi;
            }
#ifdef SUBDIVIDE
        }
#endif
    }
    return float4(d, id_hit.x, id_hit.y, boxID_hit);
}

// Scene SDF
float map(float3 p) {
    float fl = -p.z + 0.1;
    float4 d4_blocks = blocks(p);
    gID = d4_blocks.yz;
    objID = (fl < d4_blocks.x) ? 1.0 : 0.0;
    return min(fl, d4_blocks.x);
}

// Raymarcher
float trace(in float3 ro, in float3 rd) {
    float t = 0.0, d_scene;
    [loop] 
    for (int i = 0; i < 64; i++) {
        d_scene = map(ro + rd * t);
        if (abs(d_scene) < 0.001 || t > FAR) break;
        t += d_scene * 0.7;
    }
    return min(t, FAR);
}

// Normals
float3 getNormal(in float3 p, float t_unused) {
    const float2 e = float2(0.001, 0.0);
    return normalize(float3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Soft Shadows
float softShadow(float3 ro, float3 lp, float3 n, float k) {
    const int maxIterationsShad = 24;
    ro += n * 0.0015;
    float3 rd = lp - ro;
    float shade = 1.0;
    float t = 0.0; 
    float end_dist = max(length(rd), 0.0001);
    rd /= end_dist;

    [loop] 
    for (int i = 0; i < maxIterationsShad; i++) {
        float d_map = map(ro + rd * t);
        if (t > 1e-4) shade = min(shade, k * d_map / t); else shade = min(shade,1.0);
        
        t += clamp(d_map, 0.01, 0.25); 
        if (d_map < 0.001 || t > end_dist) break; 
    }
    return max(shade, 0.0);
}

// Ambient Occlusion
float calcAO(in float3 p, in float3 n) {
    float sca = 3.0, occ = 0.0;
    for (int i = 0; i < 5; i++) {
        float hr = (float(i) + 1.0) * 0.15 / 5.0; 
        float d_map = map(p + n * hr);
        occ += (hr - d_map) * sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

//--------------------------------------------------------------------------------------
// Main Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS_Main(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    float2 R_res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 uv = (vpos.xy - R_res * 0.5) / R_res.y;

    float time_in_seconds = AS_getTime() / 1000.0;

    float3 lk = float3(0.0, 0.0, 0.0);
    float3 ro = lk + float3(-0.5 * 0.3 * cos(time_in_seconds / 2.0), -0.5 * 0.2 * sin(time_in_seconds / 2.0), -2.0);
    float3 lp = ro + float3(1.5, 2.0, -1.0);

    float FOV = 1.0;
    float3 fwd = normalize(lk - ro);
    float3 rgt = normalize(float3(fwd.z, 0.0, -fwd.x));
    float3 up = cross(fwd, rgt);
    float3 rd = normalize(fwd + FOV * uv.x * rgt + FOV * uv.y * up);

    float t = trace(ro, rd);
    float2 svGID = gID;
    float svObjID = objID;
    float3 col = float3(0,0,0);

    if (t < FAR) {
        float3 sp = ro + rd * t;
        float3 sn = getNormal(sp, t);
        float3 texCol;

        if (svObjID < 0.5) {
            float3 tx = getTex(svGID);
#ifdef GRAYSCALE
            texCol = dot(tx, float3(0.299, 0.587, 0.114)).xxx;
#else
            texCol = tx;
#endif

#ifdef SPARKLES
            float rnd_hash = hash21(svGID); 
            float rnd2_hash = hash21(svGID + 0.037);
            float sparkle_phase = cos(rnd_hash * 6.283 + time_in_seconds * 2.0) * 0.5 + 0.5;
            float rnd_sparkle = smoothstep(0.9, 0.95, sparkle_phase);
            
            float3 rndCol_sparkle = (0.5 + 0.45 * cos(6.2831 * lerp(0.0, 0.3, rnd2_hash) + float3(0, 1, 2) / 1.1));
            rndCol_sparkle = lerp(rndCol_sparkle, rndCol_sparkle.xzy, uv.y * 0.75 + 0.5);
            
            float current_tex_luminance = dot(texCol, float3(0.299, 0.587, 0.114)); 
            float sparkle_visibility_threshold = 1.0 - ( (1.0/15.0 * 0.15) + 0.001 ); 
            rndCol_sparkle = lerp(float3(1,1,1), rndCol_sparkle * 50.0, rnd_sparkle * smoothstep(sparkle_visibility_threshold, 1.0, 1.0 - current_tex_luminance) );
            texCol *= rndCol_sparkle;
#endif
            texCol = smoothstep(0.0, 1.0, texCol);
        } else {
            texCol = float3(0,0,0);
        }
        
        float3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;

        float sh = softShadow(sp, lp, sn, 8.0);
        float ao = calcAO(sp, sn);
        sh = min(sh + ao * 0.25, 1.0);

        float atten = 1.0 / (1.0 + lDist * 0.05);
        float diff = max(dot(sn, ld), 0.0);
        float spec = pow(max(dot(reflect(ld, sn), rd), 0.0), 16.0); 
        float fre = pow(clamp(dot(sn, rd) + 1.0, 0.0, 1.0), 2.0);

        col = texCol * (diff + ao * 0.3 + float3(0.25, 0.5, 1.0) * diff * fre * 16.0 + float3(1.0, 0.5, 0.2) * spec * 2.0);
        col *= ao * sh * atten;
    }

    return float4(sqrt(max(col, 0.0)), 1.0);
}

//--------------------------------------------------------------------------------------
// Technique Definition
//--------------------------------------------------------------------------------------
technique ExtrudedBackbuffer_Simple_AS_GetTime_UVFix
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}