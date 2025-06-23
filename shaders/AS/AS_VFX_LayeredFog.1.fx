/**
 * AS_VFX_LayeredFog.1.fx - Layered Parallax Fog Effect (Screen-Space Depth)
 * Author: Leon Aquitaine (Re-architected to avoid ReShade::ViewOrigin/ViewToWorld)
 * License: Creative Commons Attribution 4.0 International
 * Original Source (Inspiration): https://www.shadertoy.com/view/Xls3D2 (Dave Hoskins)
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader generates a layered fog effect that blends with the existing scene
 * based on screen-space depth. It simulates fog accumulation by stepping along
 * a simplified ray derived from screen coordinates, stopping at the actual scene depth.
 * This creates a parallax-like effect, making the fog interact realistically with
 * subjects at different distances in the scene.
 *
 * FEATURES:
 * - Depth-aware layered fog for realistic atmospheric perspective.
 * - Parallax scrolling of fog layers based on screen depth and time.
 * - Supports multiple procedural noise types (Triangle, Four-D, Texture, Value)
 * to define the fog's appearance (e.g., wispy, volumetric, uniform).
 * - Customizable fog color, overall density, and max visibility distance.
 * - Adjustable fog animation speed (horizontal and vertical flow).
 * - Tunable fog layer offset and rotation for creative positioning relative to the screen.
 * - Seamless integration with ReShade's linearized depth buffer.
 * - Standard AS-StageFX UI controls for easy parameter adjustment.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Derives a screen-space ray direction from `texcoord` and `ReShade::AspectRatio`.
 * 2. Fetches the linearized depth (`ReShade::GetLinearizedDepth`) of the scene
 * at the current pixel, and converts it to a world-like distance.
 * 3. Uses a simplified ray-marching loop (`calculateFogDensity`) to step along
 * this screen-space ray, sampling fog density based on chosen noise type.
 * The loop stops when it hits the converted scene depth or max fog distance.
 * 4. Fog layer movement and parallax are achieved by applying time-based scrolling
 * and world-space offsets/rotations directly to the 3D sampling coordinates
 * within the noise functions, relative to the camera's assumed fixed forward vector.
 * 5. The accumulated fog density is used to `lerp` between the original
 * backbuffer color and the defined `Fog_Color`.
 * 6. Includes a debug mode to visualize the calculated fog density.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_LayeredFog_1_fx
#define __AS_VFX_LayeredFog_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh" // For Noise3d variations and AS_hash12

// ============================================================================
// UI UNIFORMS
// ============================================================================

// FOG SETTINGS
static const float FOG_PRECISION_MIN = 0.01;
static const float FOG_PRECISION_MAX = 0.5;
static const float FOG_PRECISION_DEFAULT = 0.1;
uniform float Fog_Precision <
    ui_type = "slider"; ui_label = "Ray March Precision";
    ui_min = FOG_PRECISION_MIN; ui_max = FOG_PRECISION_MAX; ui_step = 0.01; ui_default = FOG_PRECISION_DEFAULT;
    ui_category = "Fog Settings"; ui_tooltip = "Controls the precision of ray steps when accumulating fog. Lower values are more precise but slower.";
> = FOG_PRECISION_DEFAULT;

static const float FOG_MULTIPLIER_MIN = 0.1;
static const float FOG_MULTIPLIER_MAX = 1.0;
static const float FOG_MULTIPLIER_DEFAULT = 0.34;
uniform float Fog_Multiplier <
    ui_type = "slider"; ui_label = "Ray Step Multiplier";
    ui_min = FOG_MULTIPLIER_MIN; ui_max = FOG_MULTIPLIER_MAX; ui_step = 0.01; ui_default = FOG_MULTIPLIER_DEFAULT;
    ui_category = "Fog Settings"; ui_tooltip = "Adjusts how much each ray step advances, affecting fog quality vs. performance.";
> = FOG_MULTIPLIER_DEFAULT;

static const int FOG_RAY_ITERATIONS_MIN = 10;
static const int FOG_RAY_ITERATIONS_MAX = 200;
static const int FOG_RAY_ITERATIONS_DEFAULT = 90;
uniform int Fog_RayIterations <
    ui_type = "slider"; ui_label = "Ray March Iterations";
    ui_min = FOG_RAY_ITERATIONS_MIN; ui_max = FOG_RAY_ITERATIONS_MAX; ui_step = 1; ui_default = FOG_RAY_ITERATIONS_DEFAULT;
    ui_category = "Fog Settings"; ui_tooltip = "Maximum number of steps the ray takes to accumulate fog. Higher values mean denser fog but higher performance cost.";
> = FOG_RAY_ITERATIONS_DEFAULT;

static const float FOG_MAX_DISTANCE_MIN = 50.0;
static const float FOG_MAX_DISTANCE_MAX = 10000.0; // Increased max distance for larger scenes
static const float FOG_MAX_DISTANCE_DEFAULT = 110.0;
uniform float Fog_MaxDistance <
    ui_type = "slider"; ui_label = "Max Fog Visibility Distance";
    ui_min = FOG_MAX_DISTANCE_MIN; ui_max = FOG_MAX_DISTANCE_MAX; ui_step = 1.0; ui_default = FOG_MAX_DISTANCE_DEFAULT;
    ui_category = "Fog Settings"; ui_tooltip = "The maximum distance at which fog is still visible and accumulated.";
> = FOG_MAX_DISTANCE_DEFAULT;

static const float FOG_START_MIN = 0.0;
static const float FOG_START_MAX = 1000.0;
static const float FOG_START_DEFAULT = 0.0;
uniform float Fog_Start <
    ui_type = "slider"; ui_label = "Fog Start Distance";
    ui_min = FOG_START_MIN; ui_max = FOG_START_MAX; ui_step = 1.0; ui_default = FOG_START_DEFAULT;
    ui_category = "Fog Settings"; ui_tooltip = "Distance from camera where fog starts to appear. 0 = fog starts immediately.";
> = FOG_START_DEFAULT;

static const float FOG_DENSITY_MIN = 0.0;
static const float FOG_DENSITY_MAX = 5.0; // Increased max density
static const float FOG_DENSITY_DEFAULT = 0.7;
uniform float Fog_Density <
    ui_type = "slider"; ui_label = "Overall Fog Density";
    ui_min = FOG_DENSITY_MIN; ui_max = FOG_DENSITY_MAX; ui_step = 0.01; ui_default = FOG_DENSITY_DEFAULT;
    ui_category = "Fog Settings"; ui_tooltip = "Controls the overall thickness and opacity of the fog effect.";
> = FOG_DENSITY_DEFAULT;

static const float FOG_COLOR_R_DEFAULT = 0.6;
static const float FOG_COLOR_G_DEFAULT = 0.65;
static const float FOG_COLOR_B_DEFAULT = 0.7;
uniform float3 Fog_Color <
    ui_type = "color"; ui_label = "Fog Base Color";
    ui_category = "Fog Settings"; ui_tooltip = "The color of the volumetric fog.";
> = float3(FOG_COLOR_R_DEFAULT, FOG_COLOR_G_DEFAULT, FOG_COLOR_B_DEFAULT);

// FOG ANIMATION & PARALLAX
static const float FOG_TIME_WARP_MIN = -10.0; // Allow negative for reverse
static const float FOG_TIME_WARP_MAX = 10.0;
static const float FOG_TIME_WARP_DEFAULT = 7.0;
uniform float Fog_XZ_ScrollSpeed <
    ui_type = "slider"; ui_label = "Fog X/Z Scroll Speed";
    ui_min = FOG_TIME_WARP_MIN; ui_max = FOG_TIME_WARP_MAX; ui_step = 0.1; ui_default = FOG_TIME_WARP_DEFAULT;
    ui_category = "Fog Animation"; ui_tooltip = "Controls the horizontal movement speed of the fog layers.";
> = FOG_TIME_WARP_DEFAULT;

static const float FOG_VERT_SPEED_MIN = -2.0; // Allow negative
static const float FOG_VERT_SPEED_MAX = 2.0;
static const float FOG_VERT_SPEED_DEFAULT = 0.5;
uniform float Fog_VerticalSpeed <
    ui_type = "slider"; ui_label = "Fog Vertical Speed";
    ui_min = FOG_VERT_SPEED_MIN; ui_max = FOG_VERT_SPEED_MAX; ui_step = 0.01; ui_default = FOG_VERT_SPEED_DEFAULT;
    ui_category = "Fog Animation"; ui_tooltip = "Controls the vertical movement speed of the fog layers.";
> = FOG_VERT_SPEED_DEFAULT;

// FOG LAYER OFFSET - These now control the fog's "origin" relative to the view, for parallax.
static const float FOG_OFFSET_WORLD_MIN = -500.0;
static const float FOG_OFFSET_WORLD_MAX = 500.0;
uniform float Fog_Offset_World_X <
    ui_type = "slider"; ui_label = "Fog Layer Offset X";
    ui_min = FOG_OFFSET_WORLD_MIN; ui_max = FOG_OFFSET_WORLD_MAX; ui_step = 1.0; ui_default = 0.0;
    ui_category = "Fog Layer Offset"; ui_tooltip = "Offsets the fog layers horizontally relative to the view origin.";
> = 0.0;
uniform float Fog_Offset_World_Y <
    ui_type = "slider"; ui_label = "Fog Layer Offset Y";
    ui_min = FOG_OFFSET_WORLD_MIN; ui_max = FOG_OFFSET_WORLD_MAX; ui_step = 1.0; ui_default = -130.0;
    ui_category = "Fog Layer Offset"; ui_tooltip = "Offsets the fog layers vertically relative to the view origin.";
> = -130.0;
uniform float Fog_Offset_World_Z <
    ui_type = "slider"; ui_label = "Fog Layer Offset Z";
    ui_min = FOG_OFFSET_WORLD_MIN; ui_max = FOG_OFFSET_WORLD_MAX; ui_step = 1.0; ui_default = -130.0;
    ui_category = "Fog Layer Offset"; ui_tooltip = "Offsets the fog layers in depth relative to the view origin.";
> = -130.0;

AS_ROTATION_UI(Fog_SnapRotation, Fog_FineRotation) // Corrected: Removed third argument causing warning


// FOG NOISE TYPE
static const int NOISE_TYPE_TRIANGLE = 0;
static const int NOISE_TYPE_FOUR_D = 1;
static const int NOISE_TYPE_TEXTURE = 2;
static const int NOISE_TYPE_VALUE = 3;
uniform int Fog_NoiseType <
    ui_type = "combo"; ui_label = "Fog Noise Type";
    ui_items = "Triangle Noise\0Four-D Noise\0Texture Noise\0Value Noise\0";
    ui_category = "Fog Noise"; ui_tooltip = "Selects the procedural noise algorithm used to generate the fog's pattern.";
> = NOISE_TYPE_TRIANGLE;

// TEXTURE NOISE SPECIFIC (requires a texture)
#ifndef FrozenFog_Texture_Path
#define FrozenFog_Texture_Path "perlin512x8CNoise.png" // Example noise texture
#endif
#define FrozenFog_Texture_WIDTH 512.0f
#define FrozenFog_Texture_HEIGHT 512.0f

texture FrozenFog_NoiseTexture <
    source = FrozenFog_Texture_Path;
    ui_label = "Noise Texture (for 'Texture Noise')";
    ui_tooltip = "The texture used when 'Texture Noise' type is selected. (perlin512x8CNoise.png recommended)";
>{
    Width = FrozenFog_Texture_WIDTH; Height = FrozenFog_Texture_HEIGHT; Format = RGBA8;
};
sampler FrozenFog_NoiseSampler { Texture = FrozenFog_NoiseTexture; AddressU = REPEAT; AddressV = REPEAT; };


AS_BLENDMODE_UI_DEFAULT(LayeredFog_BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(LayeredFog_BlendAmount)

// DEBUG FLAG
uniform bool Debug_Enable <
    ui_type = "checkbox"; ui_label = "Show Fog Effect Mask (Turns screen red)";
    ui_category = "Debug"; ui_tooltip = "If enabled, visualizes the calculated fog density as a red mask for debugging.";
> = false;


// ============================================================================
// CONSTANTS & HELPERS (from original shader, minimal changes)
// ============================================================================

#define MOD3 float3(.16532,.17369,.15787)
#define MOD2 float2(.16632,.17369)

float tri(in float x){return abs(frac(x)-.5);}
float hash12(float2 p){return AS_hash12(p);} // Using AS_Noise.1.fxh hash


// ============================================================================
// NOISE FUNCTIONS - Adapted from original shader
// ============================================================================

float3 tri3(in float3 p){return float3( tri(p.z+tri(p.y)), tri(p.z+tri(p.x)), tri(p.y+tri(p.x)));}

float Noise3d_Triangle(in float3 p)
{
    float z_val = 1.4;
	float rz = 0.0;
    float3 bp = p;
	for (int i=0; i<= 2; i++ )
	{
        float3 dg = tri3(bp);
        p += (dg);

        bp *= 2.0;
		z_val *= 1.5;
		p *= 1.3;
		
        rz += (tri(p.z+tri(p.x+tri(p.y))))/z_val;
        bp += 0.14;
	}
	return rz;
}

float4 quad(in float4 p){return abs(frac(p.yzwx+p.wzxy)-.5);}

float Noise3d_FourD(in float3 q, in float time_param)
{
    float z_val = 1.4;
    float4 p_val = float4(q, time_param * 0.1);
	float rz = 0.0;
    float4 bp = p_val;
	for (int i=0; i<= 2; i++ )
	{
        float4 dg = quad(bp);
        p_val += (dg);

		z_val *= 1.5;
		p_val *= 1.3;
		
        rz += (tri(p_val.z+tri(p_val.w+tri(p_val.y+tri(p_val.x)))))/z_val;
		
        bp = bp.yxzw*2.0+.14;
	}
	return rz;
}

float Noise3d_Texture(in float3 x)
{
    x *= 10.0;
    float h = 0.0;
    float a = 0.28;
    for (int i = 0; i < 4; i++)
    {
        float3 p_floor = floor(x);
        float3 f_frac = frac(x);
        f_frac = f_frac*f_frac*(3.0-2.0*f_frac);

        float2 uv_sampled = (p_floor.xy + float2(37.0,17.0)*p_floor.z) + f_frac.xy;
        float2 rg = tex2Dlod(FrozenFog_NoiseSampler, float4((uv_sampled + 0.5) / float2(FrozenFog_Texture_WIDTH, FrozenFog_Texture_HEIGHT), 0.0, 0.0)).yx;
        h += lerp( rg.x, rg.y, f_frac.z )*a;
        a *= 0.5;
        x += x; // Equivalent to x *= 2.0
    }
    return h;
}

float Hash(float3 p){
	p = frac(p * MOD3);
    p += dot(p.xyz, p.yzx + 19.19);
    return frac(p.x * p.y * p.z);
}

float Noise3d_Value(in float3 p)
{
    float2 add = float2(1.0, 0.0);
	p *= 10.0;
    float h = 0.0;
    float a = 0.3;
    for (int n = 0; n < 4; n++)
    {
        float3 i_floor = floor(p);
        float3 f_frac = frac(p);
        f_frac *= f_frac * (3.0-2.0*f_frac);

        h += lerp(
            lerp(lerp(Hash(i_floor), Hash(i_floor + add.xyy),f_frac.x),
                lerp(Hash(i_floor + add.yxy), Hash(i_floor + add.xxy),f_frac.x),
                f_frac.y),
            lerp(lerp(Hash(i_floor + add.yyx), Hash(i_floor + add.xyx),f_frac.x),
                lerp(Hash(i_floor + add.yxx), Hash(i_floor + add.xxx),f_frac.x),
                f_frac.y),
            f_frac.z)*a;
        a *= 0.5;
        p += p; // Equivalent to p *= 2.0
    }
    return h;
}

// Unified noise function dispatch
float GetNoise3d(in float3 p, in float time_param)
{
    switch(Fog_NoiseType)
    {
        case NOISE_TYPE_TRIANGLE: return Noise3d_Triangle(p);
        case NOISE_TYPE_FOUR_D: return Noise3d_FourD(p, time_param);
        case NOISE_TYPE_TEXTURE: return Noise3d_Texture(p);
        case NOISE_TYPE_VALUE: return Noise3d_Value(p);
        default: return Noise3d_Triangle(p); // Fallback
    }
}


// ============================================================================
// FOG CALCULATION FUNCTIONS (re-purposed from original)
// ============================================================================

// Original fogmap, adapted for general purpose fog particle density
float fogmap(in float3 p_world_offset, in float distance_from_camera_approx, in float time_param)
{
    // Apply fog movement (parallax)
    // The 'p_world_offset' here is the 3D sampling point in the fog volume.
    // The original fogmap logic already applies scrolling to these coordinates.
    p_world_offset.xz -= time_param * Fog_XZ_ScrollSpeed + sin(p_world_offset.z*0.3)*3.0; // XZ scrolling
    p_world_offset.y -= time_param * Fog_VerticalSpeed; // Vertical movement
    
    // Original noise sampling logic for fog density
    return (max(GetNoise3d(p_world_offset*0.008+0.1, time_param)-0.1,0.0)*GetNoise3d(p_world_offset*0.1, time_param))*0.3 * Fog_Density;
}

// Original fogColour, for blending fog with scene
float3 fogColour( in float3 base_color, float distance_val )
{
    // This is the original shader's "fogging" of the scene based on distance
    // We can interpret base_color as the original scene color
    float3 extinction_factor = exp2(-distance_val*0.0001*float3(1.0,1.5,3.0));
    return base_color * extinction_factor + (1.0-extinction_factor)*float3(1.0,1.0,1.0); // Blends towards white based on distance
}


/**
 * calculateFogDensity
 * Accumulates fog density along a simplified screen-space ray up to a specified depth.
 * @param screen_uv The screen-space UV coordinate (0-1).
 * @param linearized_depth The linearized depth value from ReShade::GetLinearizedDepth.
 * @param time_param Current shader time for animation.
 * @return Accumulated fog density (0.0 to 1.0).
 */
float calculateFogDensity(in float2 screen_uv, in float linearized_depth, in float time_param)
{    // Convert linearized depth to a more intuitive world-like distance.
    // Linearized depth is 0-1, we scale it to a reasonable world distance range
    float scene_world_distance = linearized_depth * Fog_MaxDistance;    float accumulated_fog_density = 0.0;
    float current_distance = Fog_Start; // Start fog accumulation at Fog_Start distance
    float step_size_multiplier = Fog_Multiplier;

    // Simulate a ray_direction from screen UVs.
    // Assuming camera at (0,0,0) looking down -Z, with Y up.
    // This creates a perspective effect for fog layers.
    float2 normalized_screen_coords = (screen_uv - 0.5) * float2(ReShade::AspectRatio, 1.0) * 2.0; // [-Aspect, Aspect] x [-1, 1]
    float3 simulated_ray_direction = normalize(float3(normalized_screen_coords.x, normalized_screen_coords.y, -1.0)); // Z is depth axis

    // Apply fog layer rotation to the simulated ray direction
    float fog_layer_rotation_radians = AS_getRotationRadians(Fog_SnapRotation, Fog_FineRotation);
    if (fog_layer_rotation_radians != 0.0)
    {
        float cos_rot = cos(fog_layer_rotation_radians);
        float sin_rot = sin(fog_layer_rotation_radians);
        simulated_ray_direction.xz = float2(simulated_ray_direction.x * cos_rot - simulated_ray_direction.z * sin_rot,
                                            simulated_ray_direction.x * sin_rot + simulated_ray_direction.z * cos_rot);
    }


    // The 'ray_origin' for fog sampling is now the Fog Layer Offset
    // This allows parallax when the game camera moves without needing ViewOrigin/ViewToWorld
    float3 fog_volume_origin = float3(Fog_Offset_World_X, Fog_Offset_World_Y, Fog_Offset_World_Z);
    for( int i=0; i<Fog_RayIterations; i++ )
    {
        // Stop if we hit the max fog distance or the actual scene geometry's distance
        if(current_distance > Fog_MaxDistance || current_distance > scene_world_distance) break;

        // Only accumulate fog if we're past the start distance
        if(current_distance >= Fog_Start)
        {
            // Calculate the 3D sampling point within the fog volume
            // This is where the simulated ray intersects the fog grid, shifted by the offset.
            float3 current_fog_sample_pos = fog_volume_origin + simulated_ray_direction * current_distance;
            
            // Accumulate fog density at this point
            accumulated_fog_density += fogmap(current_fog_sample_pos, current_distance, time_param);
        }

        // Advance the ray based on precision and original dynamic step increase logic
        current_distance += (Fog_Precision * (1.0 + current_distance * 0.05)) * step_size_multiplier;
        step_size_multiplier += 0.004;
    }
    return min(accumulated_fog_density, 1.0); // Clamp final density to 0-1
}


// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_LayeredFog(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // If debug mode is enabled, return a red mask proportional to fog density
    if (Debug_Enable)
    {
        float time_val = AS_getTime();
        float scene_linear_depth = ReShade::GetLinearizedDepth(texcoord);
        float fog_density_factor_debug = calculateFogDensity(texcoord, scene_linear_depth, time_val);
        return float4(fog_density_factor_debug, 0.0, 0.0, 1.0); // Red mask proportional to fog density
    }

    float time_val = AS_getTime();
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);

    // Get linearized depth at this pixel from the scene
    float scene_linear_depth = ReShade::GetLinearizedDepth(texcoord);

    // Calculate fog density using the simulated ray and scene depth
    // The fog_volume_origin and rotation are handled inside calculateFogDensity
    float fog_density_factor = calculateFogDensity(texcoord, scene_linear_depth, time_val);    // Convert linearized depth to a world-like distance for the distance haze effect
    // Scale linearized depth (0-1) to a reasonable distance range
    float approximated_world_distance = scene_linear_depth * Fog_MaxDistance;

    // Apply distance haze (from original shader) to the background color
    float3 distance_haze_color = fogColour(original_color.rgb, approximated_world_distance);

    // The core fog blend: Lerp between the distance_haze_color and the Fog_Color based on accumulated density.
    float3 final_color_rgb = lerp(distance_haze_color, Fog_Color.rgb, fog_density_factor);

	// Apply final blending over the original backbuffer.
    return AS_applyBlend(float4(final_color_rgb, 1.0), original_color, LayeredFog_BlendMode, LayeredFog_BlendAmount);
}

// ============================================================================
// TECHNIQUES
// ============================================================================

technique AS_VFX_LayeredFog
<
    ui_label = "[AS] VFX: Layered Fog";
    ui_tooltip = "Layered parallax fog effect with depth interaction and customizable noise patterns.\n"
                 "Creates atmospheric fog layers that interact with scene geometry.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LayeredFog;
    }
}

#endif // __AS_VFX_LayeredFog_1_fx
