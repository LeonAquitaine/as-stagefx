/**
 * AS_BGX_Extrusion.1.fx - 3D Block Extrusion Background Effect
 * Author: StageFX Team
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a 3D block extrusion effect based on the backbuffer image, with customizable
 * lighting, shadows, and subdivision. Transforms the scene into an isometric 3D blocks arrangement
 * where brighter areas are extruded higher.
 *
 * FEATURES:
 * - Adjustable block scale and extrusion height
 * - Customizable camera and lighting
 * - High-quality shadows and ambient occlusion
 * - Optional block subdivision for increased detail
 * - Optional sparkles with color tinting
 * - Full audio reactivity for animation parameters
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Samples the backbuffer to generate height data
 * 2. Creates a 3D grid of blocks with heights based on pixel brightness
 * 3. Uses raymarching to render the extruded blocks with proper lighting
 * 4. Applies shadows, AO, and custom lighting for enhanced visuals
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_Extrusion_1_fx
#define __AS_BGX_Extrusion_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// Define debug toggle UI as it seems to be missing in AS_Utils
#define AS_DEBUG_TOGGLE_UI(name, category) \
uniform bool name < ui_type = "bool"; ui_label = "Enable Debug"; ui_tooltip = "Enables debug visualizations for troubleshooting."; ui_category = category; > = false;

//--------------------------------------------------------------------------------------
// UI Uniforms for Artistic Control
//--------------------------------------------------------------------------------------

// --- Effect Main Controls ---
uniform bool EnableSubdivision < ui_category="Main Controls"; ui_label="Enable Block Subdivision"; ui_tooltip="Subdivides blocks for more detail based on height differences. Higher performance cost."; > = true;

uniform bool EnableSparkles < ui_category="Main Controls"; ui_label="Enable Sparkles"; ui_tooltip="Adds blinking sparkles to the blocks."; > = true;

uniform bool EnableGrayscale < ui_category="Main Controls"; ui_label="Enable Grayscale Blocks"; ui_tooltip="Converts block colors to grayscale."; > = false;

// --- Performance Settings ---
uniform int RaymarchSteps < ui_category="Performance"; ui_type="slider"; ui_min=32; ui_max=128; ui_step=1; ui_label="Max Raymarch Steps"; ui_tooltip="Maximum steps for the main raymarcher. Higher values are more accurate but slower."; > = 64;

uniform float FarClipDistance < ui_category="Performance"; ui_type="drag"; ui_min=5.0; ui_max=50.0; ui_step=0.1; ui_label="Far Clip Distance"; ui_tooltip="Maximum distance rays will travel."; > = 20.0;

// --- Block Parameters ---
uniform float BlockBaseScale < ui_category="Block Parameters"; ui_type="drag"; ui_min=0.01; ui_max=0.25; ui_step=0.001; ui_label="Block Base Scale"; ui_tooltip="Controls the fundamental size of the grid blocks (original was 1/16 = 0.0625)."; > = 0.0625;

// --- Audio Reactivity for Block Scale ---
AS_AUDIO_SOURCE_UI(BlockScaleAudioSource, "Block Scale Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(BlockScaleAudioMultiplier, "Block Scale Audio Multiplier", 0.0, 2.0, "Audio Reactivity")

uniform float ExtrusionHeightMultiplier < ui_category="Block Parameters"; ui_type="drag"; ui_min=0.0; ui_max=3.0; ui_step=0.01; ui_label="Extrusion Height Multiplier"; ui_tooltip="Scales the height of the extruded blocks. Higher values mean taller extrusions from brighter areas."; > = 1.0;

// --- Audio Reactivity for Extrusion Height ---
AS_AUDIO_SOURCE_UI(ExtrusionAudioSource, "Extrusion Height Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(ExtrusionAudioMultiplier, "Extrusion Audio Multiplier", 0.0, 2.0, "Audio Reactivity")

uniform float TextureMappingWorldSpan < ui_category="Block Parameters"; ui_type="drag"; ui_min=1.0; ui_max=20.0; ui_step=0.1; ui_label="Texture Mapping World Span"; ui_tooltip="Size of the world-space area (centered at origin) that the backbuffer maps to. Smaller = more zoomed-in texture on blocks."; > = 4.0;

// --- Camera & Lighting ---
// Standard position and rotation controls for stage effects
uniform float2 EffectPosition < ui_type = "drag"; ui_label = "Position"; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_tooltip = "Adjusts the position of the effect."; ui_category = "Camera & Lighting"; > = float2(0.0, 0.0);
uniform int EffectRotationSnap < ui_type = "combo"; ui_label = "Rotation Snap"; ui_items = "0°\00.25°\00.5°\00.75°\01°\01.25°\01.5°\01.75°\02°\0"; ui_category = "Camera & Lighting"; > = 0;
uniform float EffectRotationFine < ui_type = "drag"; ui_label = "Fine Rotation"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.01; ui_category = "Camera & Lighting"; > = 0.0;

uniform float CameraBaseZ < ui_category="Camera & Lighting";
    ui_type="drag"; ui_min=-10.0; ui_max=1.0; ui_step=0.1;
    ui_label="Camera Base Z Position";
    ui_tooltip="Base Z coordinate of the camera (original was -2.0).";
> = -2.0;

uniform float3 LightPositionOffset < ui_category="Camera & Lighting";
    ui_type="drag"; ui_min=-5.0; ui_max=5.0; ui_step=0.1;
    ui_label="Light Position Offset (from Camera)";
    ui_tooltip="Offset of the light source relative to the camera position.";
> = float3(1.5, 2.0, -1.0);

uniform float FOV_Degrees < ui_category="Camera & Lighting";
    ui_type="drag"; ui_min=20.0; ui_max=120.0; ui_step=1.0;
    ui_label="Field of View (Degrees)";
    ui_tooltip="Camera's vertical field of view in degrees.";
> = 60.0;


// --- Shadows & Ambient Occlusion ---
uniform float ShadowSoftnessFactor < ui_category="Shadows & Ambient Occlusion";
    ui_type="drag"; ui_min=1.0; ui_max=64.0; ui_step=1.0;
    ui_label="Shadow Softness Factor (k)";
    ui_tooltip="Controls the softness of raymarched shadows. Higher values can make shadows softer but might need more steps.";
> = 8.0;

uniform int ShadowMaxSteps < ui_category="Shadows & Ambient Occlusion";
    ui_type="slider"; ui_min=4; ui_max=48; ui_step=1;
    ui_label="Max Shadow Steps";
    ui_tooltip="Maximum steps for shadow rays. Higher = better quality but slower.";
> = 24;

uniform float AOStrength < ui_category="Shadows & Ambient Occlusion";
    ui_type="drag"; ui_min=0.0; ui_max=3.0; ui_step=0.01;
    ui_label="Ambient Occlusion Strength";
    ui_tooltip="Controls the intensity of the ambient occlusion effect.";
> = 1.0;

uniform int AOSamples < ui_category="Shadows & Ambient Occlusion";
    ui_type="slider"; ui_min=1; ui_max=8; ui_step=1;
    ui_label="Ambient Occlusion Samples";
    ui_tooltip="Number of samples for AO. Higher = smoother AO but slower.";
> = 5;

uniform float AORadiusScale < ui_category="Shadows & Ambient Occlusion";
    ui_type="drag"; ui_min=0.1; ui_max=3.0; ui_step=0.01;
    ui_label="Ambient Occlusion Radius Scale";
    ui_tooltip="Scales the sampling radius for AO. Affects how far AO reaches.";
> = 1.0;


// --- Sparkles (if EnableSparkles is true) ---
uniform float SparkleEffectIntensity < ui_category="Sparkle Effect";
    ui_type="drag"; ui_min=0.0; ui_max=100.0; ui_step=1.0;
    ui_label="Sparkle Color Intensity";
    ui_tooltip="Multiplier for the colored sparkles. Set to 0 to disable color impact if SPARKLES define is on but you want them subtle.";
> = 50.0;

uniform float SparkleAnimationSpeed < ui_category="Sparkle Effect";
    ui_type="drag"; ui_min=0.0; ui_max=5.0; ui_step=0.1;
    ui_label="Sparkle Animation Speed";
    ui_tooltip="Speed of the blinking sparkle animation.";
> = 2.0;

// --- Animation ---
AS_ANIMATION_SPEED_UI(AnimationSpeed, "Animation")

// --- Stage Controls ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix / Blend ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Blend Mode"; ui_items = "Normal\0Darken\0Multiply\0Color Burn\0Linear Burn\0Lighten\0Screen\0Color Dodge\0Linear Dodge\0Overlay\0Soft Light\0Hard Light\0Vivid Light\0Linear Light\0Pin Light\0Hard Mix\0Difference\0Exclusion\0Subtract\0Divide\0Reflect\0Hue\0Saturation\0Color\0Luminosity\0"; ui_tooltip = "Blend mode to apply when combining this effect with the backbuffer."; ui_category = "Final Mix"; > = 0;
uniform float BlendOpacity < ui_category = "Final Mix"; ui_type = "slider"; ui_label = "Opacity"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_tooltip = "Controls the strength of the effect."; > = 1.0;

// --- Debug ---
AS_DEBUG_TOGGLE_UI(ShowDebug, "Debug")
uniform int DebugMode < ui_category = "Debug"; ui_type = "combo"; ui_label = "Debug Mode"; ui_items = "Normal Out\0Height Values\0Normals\0Shadows\0AO\0"; ui_tooltip = "Displays different debug visualizations of the blocks."; > = 0;

// Global variables to pass hit information
static float objID;
static float2 gID;

// Standard 2D rotation formula.
float2x2 rot2(in float a) {
    float c = cos(a), s = sin(a);
    return float2x2(c, -s, s, c);
}

// Use AS hash function from utils
float hash21(float2 p) {
    return AS_hash21(p);
}

// Getting the video texture (ReShade BackBuffer).
float3 getTex(float2 p) { // p is svGID (world coordinates of block cell)
    float2 uv_coords = p / TextureMappingWorldSpan + 0.5;
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

// Helper: Get current animation time
float getTime() {
    return AS_getAnimationTime(AnimationSpeed, 0.0);
}

// Extruded block grid
float4 blocks(float3 q3) {
    // Apply audio reactivity to block scale
    float current_scale = AS_applyAudioReactivity(BlockBaseScale, BlockScaleAudioSource, BlockScaleAudioMultiplier, true);
    const float2 l = float2(current_scale, current_scale);
    const float2 s = l * 2.0;

    float d = 1e5;
    float2 p_local, ip;
    float2 id_hit = float2(0,0);
    float2 cntr_offset;

    static const float2 ps4_offsets[4] = { // Renamed for clarity from ps4
        float2(-l.x, l.y), l, -l, float2(l.x, -l.y)
    };
    float boxID_hit = 0.0;

    for (int i = 0; i < 4; i++) {
        cntr_offset = ps4_offsets[i] / 2.0; // Use renamed static const array
        p_local = q3.xy - cntr_offset;
        ip = floor(p_local / s) + 0.5;
        p_local -= ip * s;
        float2 idi = ip * s + cntr_offset;        float h_raw = hm(idi); // Raw height from 0-1

        // Apply audio reactivity to extrusion height
        float extrusion_mult = AS_applyAudioReactivity(ExtrusionHeightMultiplier, ExtrusionAudioSource, ExtrusionAudioMultiplier, true);
        
        float h_scaled; // This will be the final height after quantization and multiplier

        if (!EnableSubdivision) {
            h_scaled = floor(h_raw * 15.999) / 15.0 * (0.15 * extrusion_mult);
        } else { // Subdivision enabled
            float4 h4_sub_raw; 
            int sub_flag = 0;
            for (int j = 0; j < 4; j++) { 
                h4_sub_raw[j] = hm(idi + ps4_offsets[j] / 4.0);
                if (abs(h4_sub_raw[j] - h_raw) > 1.0 / 15.0) sub_flag = 1; // Compare raw heights for subdivision decision
            }            h_scaled = floor(h_raw * 15.999) / 15.0 * (0.15 * extrusion_mult);
            float4 h4_sub_scaled = floor(h4_sub_raw * 15.999) / 15.0 * (0.15 * extrusion_mult);

            if (sub_flag == 1) {
                float4 d4_sub_sdf, d4_sub_extruded; 
                for (int j = 0; j < 4; j++) { 
                    d4_sub_sdf[j] = sBoxS(p_local - ps4_offsets[j] / 4.0, l / 4.0 - 0.05 * current_scale, 0.005);
                    // Use h4_sub_scaled for extrusion height
                    d4_sub_extruded[j] = opExtrusion(d4_sub_sdf[j], (q3.z + h4_sub_scaled[j]), h4_sub_scaled[j]);
                    if (d4_sub_extruded[j] < d) {
                        d = d4_sub_extruded[j];
                        id_hit = idi + ps4_offsets[j] / 4.0;
                    }
                }
                 // After handling subdivided blocks, return or skip the main block logic for this cell part
                continue; // Ensure we don't also process the non-subdivided case for this 'i'
            }
            // If not subdividing this particular block (sub_flag == 0), h_scaled is already prepared.
        }
        
        // This part is reached if !EnableSubdivision OR (EnableSubdivision AND sub_flag == 0)
        float di2D = sBoxS(p_local, l / 2.0 - 0.05 * current_scale, 0.015);
        float di = opExtrusion(di2D, (q3.z + h_scaled), h_scaled); // Use h_scaled
        if (di < d) {
            d = di;
            id_hit = idi;
        }
    }
    return float4(d, id_hit.x, id_hit.y, boxID_hit);
}

// Scene SDF
float map(float3 p) {
    float fl = -p.z + 0.1; // Floor definition could also be made tunable
    float4 d4_blocks = blocks(p);
    gID = d4_blocks.yz;
    objID = (fl < d4_blocks.x) ? 1.0 : 0.0;
    return min(fl, d4_blocks.x);
}

// Raymarcher
float trace(in float3 ro, in float3 rd) {
    float t = 0.0, d_scene;
    [loop] 
    for (int i = 0; i < RaymarchSteps; i++) { // Use uniform
        d_scene = map(ro + rd * t);
        if (abs(d_scene) < 0.001 || t > FarClipDistance) break; // Use uniform
        t += d_scene * 0.7; // Ray step factor, could be tunable
    }
    return min(t, FarClipDistance); // Use uniform
}

// Normals
float3 getNormal(in float3 p, float t_unused) {
    const float2 e = float2(0.001, 0.0); // Epsilon for normal calc, could be tunable
    return normalize(float3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Soft Shadows
float softShadow(float3 ro, float3 lp, float3 n, float k_softness) { // k_softness from uniform
    ro += n * 0.0015;
    float3 rd = lp - ro;
    float shade = 1.0;
    float t = 0.001; // Start t slightly above 0 to avoid potential division by zero if d_map is huge initially
    float end_dist = max(length(rd), 0.0001);
    rd /= end_dist;

    [loop] 
    for (int i = 0; i < ShadowMaxSteps; i++) { // Use uniform
        float d_map = map(ro + rd * t);
        // Ensure t is not zero, k_softness is from uniform ShadowSoftnessFactor
        shade = min(shade, k_softness * d_map / t); 
        
        t += clamp(d_map, 0.01, 0.25); // Step distance params could be tunable
        if (d_map < 0.001 || t > end_dist) break; 
    }
    return max(shade, 0.0);
}

// Ambient Occlusion
float calcAO(in float3 p, in float3 n) {
    float sca = 3.0; // Initial scale for AO contribution, could be tunable
    float occ = 0.0;
    for (int i = 0; i < AOSamples; i++) { // Use uniform
        // AORadiusScale influences how far samples are taken
        float hr = (float(i) + 1.0) * (0.15 * AORadiusScale) / float(AOSamples); 
        float d_map = map(p + n * hr);
        occ += (hr - d_map) * sca;
        sca *= 0.7; // Attenuation factor for further samples, could be tunable
    }
    return clamp(1.0 - (occ * AOStrength), 0.0, 1.0); // Use uniform AOStrength
}

//--------------------------------------------------------------------------------------
// Main Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS_Main(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {    // Get original color for blending
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
      // Check if we should apply the effect based on depth
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) {
        return originalColor; // Return original color for pixels closer than the effect depth
    }
    
    // Apply position and rotation from standard AS controls
    float2 positionedCoord = texcoord;
    float2 centered = positionedCoord - 0.5;
    
    // Calculate rotation in radians from the standard AS rotation controls
    float rotationRadians = radians(EffectRotationSnap * 45.0 + EffectRotationFine);
    if (abs(rotationRadians) > 0.001) {
        // Rotate around center if needed
        float s = sin(rotationRadians);
        float c = cos(rotationRadians);
        centered = float2(
            centered.x * c - centered.y * s,
            centered.x * s + centered.y * c
        );
    }
    
    // Apply position offset
    centered.x -= EffectPosition.x / BUFFER_WIDTH * BUFFER_HEIGHT;
    centered.y += EffectPosition.y;
    positionedCoord = centered + 0.5;
    
    // Skip processing if outside screen bounds
    if (positionedCoord.x < 0 || positionedCoord.x > 1 || 
        positionedCoord.y < 0 || positionedCoord.y > 1) {
        return originalColor;
    }
    
    float2 R_res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 uv = (vpos.xy - R_res * 0.5) / R_res.y;

    float time_in_seconds = getTime() / 1000.0;

    // Camera Setup
    float3 lk = float3(0.0, 0.0, 0.0); // Look at point
    // Animated camera base position before applying Z offset
    float3 cam_base_anim_pos = float3(-0.5 * 0.3 * cos(time_in_seconds / 2.0), -0.5 * 0.2 * sin(time_in_seconds / 2.0), 0.0);
    float3 ro = lk + cam_base_anim_pos + float3(0.0, 0.0, CameraBaseZ); // Apply CameraBaseZ

    float3 lp = ro + LightPositionOffset; // Light position based on camera and offset uniform

    // FOV calculation
    float fov_rad_half = radians(FOV_Degrees) / 2.0;
    float fov_param = tan(fov_rad_half);

    float3 fwd = normalize(lk - ro);
    float3 rgt = normalize(cross(fwd, float3(0,1,0))); // More robust right vector calculation assuming Y is up
    if (abs(fwd.y) > 0.999) rgt = float3(1,0,0); // Handle looking straight up/down
    float3 up = cross(rgt, fwd); // Recalculate up vector
    
    float3 rd = normalize(fwd * (1.0/fov_param) + uv.x * rgt + uv.y * up); // Adjusted rd for proper FOV
    // Simpler version if fov_param is direct scale on uv components:
    // rd = normalize(fwd + fov_param * uv.x * rgt + fov_param * uv.y * up); // Original style
    float t = trace(ro, rd);
    float2 svGID = gID;
    float svObjID = objID;
    float3 col = float3(0,0,0);
    
    // Initialize these variables outside the if block so they're in scope for debug visualizations
    float3 sp = ro + rd * t;
    float3 sn = float3(0,1,0); // Default normal pointing up
    float sh = 1.0; // Default shadow value (fully lit)
    float ao_val = 1.0; // Default AO value (no occlusion)
    float3 texCol = float3(0,0,0);

    if (t < FarClipDistance) { // Use uniform
        sp = ro + rd * t;
        sn = getNormal(sp, t);

        if (svObjID < 0.5) { // Hit extruded grid
            float3 tx = getTex(svGID);
            if (EnableGrayscale) {
                texCol = dot(tx, float3(0.299, 0.587, 0.114)).xxx;
            } else {
                texCol = tx;
            }            if (EnableSparkles) {
                float rnd_hash = hash21(svGID); 
                float rnd2_hash = hash21(svGID + 0.037);
                // Use animation framework
                float sparkle_time = time_in_seconds * SparkleAnimationSpeed;
                float sparkle_phase = cos(rnd_hash * AS_TWO_PI + sparkle_time) * 0.5 + 0.5;
                float rnd_sparkle = smoothstep(0.9, 0.95, sparkle_phase);
                
                float3 rndCol_sparkle = (0.5 + 0.45 * cos(6.2831 * lerp(0.0, 0.3, rnd2_hash) + float3(0, 1, 2) / 1.1));
                rndCol_sparkle = lerp(rndCol_sparkle, rndCol_sparkle.xzy, uv.y * 0.75 + 0.5);
                
                float current_tex_luminance = dot(texCol, float3(0.299, 0.587, 0.114)); 
                float sparkle_visibility_threshold = 1.0 - ( (1.0/15.0 * (0.15 * ExtrusionHeightMultiplier)) + 0.001 ); 
                // Use SparkleEffectIntensity
                rndCol_sparkle = lerp(float3(1,1,1), rndCol_sparkle * SparkleEffectIntensity, rnd_sparkle * smoothstep(sparkle_visibility_threshold, 1.0, 1.0 - current_tex_luminance) );
                texCol *= rndCol_sparkle;
            }
            texCol = smoothstep(0.0, 1.0, texCol);
        } else { // Hit floor
            texCol = float3(0,0,0);
        }
        
        float3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;

        float sh = softShadow(sp, lp, sn, ShadowSoftnessFactor); // Use uniform
        float ao_val = calcAO(sp, sn); // ao_val is already 0-1 range with strength applied
        
        sh = min(sh + ao_val * 0.25, 1.0); // Modulate shadow by some AO

        float atten = 1.0 / (1.0 + lDist * 0.05); // Attenuation factor, could be tunable
        float diff = max(dot(sn, ld), 0.0);
        float spec = pow(max(dot(reflect(ld, sn), rd), 0.0), 16.0); // Shininess could be tunable
        float fre = pow(clamp(dot(sn, rd) + 1.0, 0.0, 1.0), 2.0); // Fresnel power could be tunable

        // Base lighting, diffuse component scaled by texCol
        col = texCol * diff;
        // Additive components
        col += texCol * ao_val * 0.3; // AO contribution to color
        col += texCol * float3(0.25, 0.5, 1.0) * diff * fre * 16.0; // Fresnel colored light
        col += texCol * float3(1.0, 0.5, 0.2) * spec * 2.0; // Specular highlights        col *= sh * atten; // Apply shadow and attenuation
    }
    
    // Apply debug visualization modes if enabled
    if (ShowDebug) {
        float3 debugCol = col;
        
        switch(DebugMode) {
            case 0: // Normal output - no change
                debugCol = col;
                break;
            case 1: // Height values
                float height = hm(gID) * ExtrusionHeightMultiplier;
                debugCol = float3(height, height, height);
                break;
            case 2: // Normal visualization
                if (objID < 0.5) { // Only modify if hit an object with normal
                    debugCol = (sn * 0.5 + 0.5); // Convert normals to 0-1 range
                }
                break;
            case 3: // Shadows
                debugCol = float3(sh, sh, sh);
                break;
            case 4: // AO
                float ao = calcAO(sp, sn);
                debugCol = float3(ao, ao, ao);
                break;
        }
        
        col = debugCol;
    }
      // Apply gamma correction
    col = sqrt(max(col, 0.0));
    
    // Final rgba result
    float4 color = float4(col, 1.0);
      // Apply blend mode with original color
    if (BlendOpacity > 0) {
        color.rgb = AS_ApplyBlend(color, originalColor, BlendMode, BlendOpacity).rgb;
    } else {
        color.rgb = originalColor.rgb;
    }
      return color;
}

//--------------------------------------------------------------------------------------
// Technique Definition
//--------------------------------------------------------------------------------------
technique AS_BGX_Extrusion_1
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}

#endif