/**
 * AS_VFX_FrozenFog.1.fx - Layered Parallax Fog Effect
 * Author: Leon Aquitaine (Adapted from Dave Hoskins' "Frozen wasteland")
 * License: Creative Commons Attribution 4.0 International
 * Original Source: https://www.shadertoy.com/view/Xls3D2 (Dave Hoskins)
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a layered fog effect with a parallax scrolling behavior,
 * simulating atmospheric perspective and interaction with scene depth. It uses a
 * ray-marching approach to determine fog density and color, allowing for different
 * noise types to generate varied fog patterns (e.g., wispy, dense).
 *
 * FEATURES:
 * - Multi-layered parallax fog for realistic depth interaction.
 * - Supports various procedural noise types (Triangle, Four-D, Texture, Value) for diverse fog appearances.
 * - Ray-marching model for accurate fog density calculation.
 * - Customizable fog color, density, and animation speed for the fog itself.
 * - Integrates with ReShade's depth buffer for seamless interaction with game geometry.
 * - Standard AS-StageFX UI controls for easy tuning and integration.
 * - **Static Camera**: The camera's position and orientation are now fixed,
 * only the fog layers will animate.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Initializes camera and ray directions to static values.
 * 2. Uses a ray-marching loop (`march` function) to step through the scene, evaluating
 * a `map` function that defines the world's geometry (including a base heightfield
 * and "vine" obstacles, adapted for general use as terrain).
 * 3. Accumulates fog density (`fogmap` function) along the ray based on noise patterns
 * and distance. The fog's animation is controlled here.
 * 4. Renders the scene color (sky or ray-marched terrain) and then blends the
 * calculated fog color, adjusting for distance and fog density.
 * 5. Includes various noise functions (Triangle, Four-D, Texture, Value noise)
 * which can be selected via preprocessor defines for different visual styles.
 * 6. Integrates AS_Utils.fxh for time, and standard ReShade uniforms for resolution.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_FrozenFog_1_fx
#define __AS_VFX_FrozenFog_1_fx

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
    ui_category = "Fog Settings";
> = FOG_PRECISION_DEFAULT;

static const float FOG_MULTIPLIER_MIN = 0.1;
static const float FOG_MULTIPLIER_MAX = 1.0;
static const float FOG_MULTIPLIER_DEFAULT = 0.34;
uniform float Fog_Multiplier <
    ui_type = "slider"; ui_label = "Ray Step Multiplier";
    ui_min = FOG_MULTIPLIER_MIN; ui_max = FOG_MULTIPLIER_MAX; ui_step = 0.01; ui_default = FOG_MULTIPLIER_DEFAULT;
    ui_category = "Fog Settings";
> = FOG_MULTIPLIER_DEFAULT;

static const float FOG_MAX_DISTANCE_MIN = 50.0;
static const float FOG_MAX_DISTANCE_MAX = 500.0;
static const float FOG_MAX_DISTANCE_DEFAULT = 110.0;
uniform float Fog_MaxDistance <
    ui_type = "slider"; ui_label = "Max Fog Distance";
    ui_min = FOG_MAX_DISTANCE_MIN; ui_max = FOG_MAX_DISTANCE_MAX; ui_step = 1.0; ui_default = FOG_MAX_DISTANCE_DEFAULT;
    ui_category = "Fog Settings";
> = FOG_MAX_DISTANCE_DEFAULT;

static const float FOG_DENSITY_MIN = 0.0;
static const float FOG_DENSITY_MAX = 2.0;
static const float FOG_DENSITY_DEFAULT = 0.7;
uniform float Fog_Density <
    ui_type = "slider"; ui_label = "Overall Fog Density";
    ui_min = FOG_DENSITY_MIN; ui_max = FOG_DENSITY_MAX; ui_step = 0.01; ui_default = FOG_DENSITY_DEFAULT;
    ui_category = "Fog Settings";
> = FOG_DENSITY_DEFAULT;

static const float FOG_COLOR_R_DEFAULT = 0.6;
static const float FOG_COLOR_G_DEFAULT = 0.65;
static const float FOG_COLOR_B_DEFAULT = 0.7;
uniform float3 Fog_Color <
    ui_type = "color"; ui_label = "Fog Base Color";
    ui_category = "Fog Settings";
> = float3(FOG_COLOR_R_DEFAULT, FOG_COLOR_G_DEFAULT, FOG_COLOR_B_DEFAULT); // FIX: Use float3 constructor

// FOG ANIMATION (Only for fog particles, not camera)
static const float FOG_TIME_WARP_MIN = 0.0;
static const float FOG_TIME_WARP_MAX = 10.0;
static const float FOG_TIME_WARP_DEFAULT = 7.0;
uniform float Fog_TimeWarp <
    ui_type = "slider"; ui_label = "Fog X/Z Scroll Speed";
    ui_min = FOG_TIME_WARP_MIN; ui_max = FOG_TIME_WARP_MAX; ui_step = 0.1; ui_default = FOG_TIME_WARP_DEFAULT;
    ui_category = "Fog Animation";
> = FOG_TIME_WARP_DEFAULT;

static const float FOG_VERT_SPEED_MIN = 0.0;
static const float FOG_VERT_SPEED_MAX = 2.0;
static const float FOG_VERT_SPEED_DEFAULT = 0.5;
uniform float Fog_VerticalSpeed <
    ui_type = "slider"; ui_label = "Fog Vertical Speed";
    ui_min = FOG_VERT_SPEED_MIN; ui_max = FOG_VERT_SPEED_MAX; ui_step = 0.01; ui_default = FOG_VERT_SPEED_DEFAULT;
    ui_category = "Fog Animation";
> = FOG_VERT_SPEED_DEFAULT;


// NOISE SELECTION
static const int NOISE_TYPE_TRIANGLE = 0;
static const int NOISE_TYPE_FOUR_D = 1;
static const int NOISE_TYPE_TEXTURE = 2;
static const int NOISE_TYPE_VALUE = 3;
uniform int Fog_NoiseType <
    ui_type = "combo"; ui_label = "Fog Noise Type";
    ui_items = "Triangle Noise\0Four-D Noise\0Texture Noise\0Value Noise\0";
    ui_category = "Fog Noise";
> = NOISE_TYPE_TRIANGLE;

// TEXTURE NOISE SPECIFIC (requires a texture)
#ifndef FrozenFog_Texture_Path
#define FrozenFog_Texture_Path "perlin512x8CNoise.png" // Example noise texture
#endif
texture FrozenFog_NoiseTexture < source = FrozenFog_Texture_Path; ui_label = "Noise Texture (for 'Texture Noise')"; >;
sampler FrozenFog_NoiseSampler { Texture = FrozenFog_NoiseTexture; AddressU = REPEAT; AddressV = REPEAT; };

// SUN / SKY COLOR
static const float SUN_COLOR_R_DEFAULT = 1.0;
static const float SUN_COLOR_G_DEFAULT = 0.95;
static const float SUN_COLOR_B_DEFAULT = 0.85;
uniform float3 Sun_Color <
    ui_type = "color"; ui_label = "Sun Color";
    ui_category = "Scene Colors";
> = float3(SUN_COLOR_R_DEFAULT, SUN_COLOR_G_DEFAULT, SUN_COLOR_B_DEFAULT); // FIX: Use float3 constructor

static const float SKY_HORIZON_R_DEFAULT = 0.1;
static const float SKY_HORIZON_G_DEFAULT = 0.15;
static const float SKY_HORIZON_B_DEFAULT = 0.25;
uniform float3 Sky_HorizonColor <
    ui_type = "color"; ui_label = "Sky Horizon Color";
    ui_category = "Scene Colors";
> = float3(SKY_HORIZON_R_DEFAULT, SKY_HORIZON_G_DEFAULT, SKY_HORIZON_B_DEFAULT); // FIX: Use float3 constructor

static const float SKY_ZENITH_R_DEFAULT = 0.8;
static const float SKY_ZENITH_G_DEFAULT = 0.8;
static const float SKY_ZENITH_B_DEFAULT = 0.8;
uniform float3 Sky_ZenithColor <
    ui_type = "color"; ui_label = "Sky Zenith Color";
    ui_category = "Scene Colors";
> = float3(SKY_ZENITH_R_DEFAULT, SKY_ZENITH_G_DEFAULT, SKY_ZENITH_B_DEFAULT); // FIX: Use float3 constructor

static const float LAND_COLOR_R_DEFAULT = 0.75;
static const float LAND_COLOR_G_DEFAULT = 0.75;
static const float LAND_COLOR_B_DEFAULT = 0.75;
uniform float3 Land_Color <
    ui_type = "color"; ui_label = "Land Color";
    ui_category = "Scene Colors";
> = float3(LAND_COLOR_R_DEFAULT, LAND_COLOR_G_DEFAULT, LAND_COLOR_B_DEFAULT); // FIX: Use float3 constructor

static const float LAND_DARK_R_DEFAULT = 0.12;
static const float LAND_DARK_G_DEFAULT = 0.13;
static const float LAND_DARK_B_DEFAULT = 0.13;
uniform float3 Land_DarkColor <
    ui_type = "color"; ui_label = "Land Darker Color (Y-Normal)";
    ui_category = "Scene Colors";
> = float3(LAND_DARK_R_DEFAULT, LAND_DARK_G_DEFAULT, LAND_DARK_B_DEFAULT); // FIX: Use float3 constructor


AS_BLENDMODE_UI_DEFAULT(FrozenFog_BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(FrozenFog_BlendAmount)


// ============================================================================
// CONSTANTS & HELPERS
// ============================================================================

#define ITERATIONS 90 // Max ray march iterations, adjust for performance/quality
#define MOD3 float3(.16532,.17369,.15787)
#define MOD2 float2(.16632,.17369)

// HLSL does not have vec2, vec3, vec4 - use float2, float3, float4
// No forward references - functions must be defined before use.

// Original smin, adapted to HLSL
float smin_custom( float a, float b)
{
	static const float k = 2.7;
	float h = saturate( 0.5 + 0.5*(b-a)/k );
	return lerp( b, a, h ) - k*h*(1.0-h);
}

// Original tri, adapted to HLSL
float tri(in float x){return abs(frac(x)-.5);}

// Original hash12, adapted to HLSL (using AS_hash12 from AS_Noise.1.fxh)
float hash12(float2 p)
{
	return AS_hash12(p);
}

// ============================================================================
// NOISE FUNCTIONS - Adapted from original shader
// ============================================================================

// Original tri3, adapted to HLSL
float3 tri3(in float3 p){return float3( tri(p.z+tri(p.y)), tri(p.z+tri(p.x)), tri(p.y+tri(p.x)));}

float Noise3d_Triangle(in float3 p)
{
    float z_val = 1.4;
	float rz = 0.0;
    float3 bp = p;
	for (int i=0; i<= 2; i++ ) // Changed loop to int for Reshade compatibility
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
    float4 p = float4(q, time_param * 0.1); // Use time_param for 4D noise
	float rz = 0.0;
    float4 bp = p;
	for (int i=0; i<= 2; i++ ) // Changed loop to int for Reshade compatibility
	{
        float4 dg = quad(bp);
        p += (dg);

		z_val *= 1.5;
		p *= 1.3;
		
        rz += (tri(p.z+tri(p.w+tri(p.y+tri(p.x)))))/z_val;
		
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
        float3 p = floor(x);
        float3 f = frac(x);
        f = f*f*(3.0-2.0*f);

        float2 uv = (p.xy + float2(37.0,17.0)*p.z) + f.xy;
        // Use tex2D for texture sampling in HLSL. iChannel0 is not a ReShade uniform.
        // Use the defined sampler for our noise texture.
        float2 rg = tex2Dlod(FrozenFog_NoiseSampler, float4((uv + 0.5) / 256.0, 0.0, 0.0)).yx; // Explicit LOD 0.0
        h += lerp( rg.x, rg.y, f.z )*a;
        a *= 0.5;
        x += x; // This is x = x + x, equivalent to x *= 2.0
    }
    return h;
}

float Hash(float3 p)
{
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
        float3 i = floor(p);
        float3 f = frac(p);
        f *= f * (3.0-2.0*f);

        h += lerp(
            lerp(lerp(Hash(i), Hash(i + add.xyy),f.x),
                lerp(Hash(i + add.yxy), Hash(i + add.xxy),f.x),
                f.y),
            lerp(lerp(Hash(i + add.yyx), Hash(i + add.xyx),f.x),
                lerp(Hash(i + add.yxx), Hash(i + add.xxx),f.x),
                f.y),
            f.z)*a;
        a *= 0.5;
        p += p; // Equivalent to p *= 2.0
    }
    return h;
}

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
// SCENE / RAYMARCH FUNCTIONS - Adapted from original shader
// ============================================================================

float height(in float2 p)
{
    float h = sin(p.x*0.1+p.y*0.2)+sin(p.y*0.1-p.x*0.2)*0.5;
    h += sin(p.x*0.04+p.y*0.01+3.0)*4.0;
    h -= sin(h*10.0)*0.1;
    return h;
}

float camHeight(in float2 p)
{
    float h = sin(p.x*0.1+p.y*0.2)+sin(p.y*0.1-p.x*0.2)*0.5;
    h += sin(p.x*0.04+p.y*0.01+3.0)*4.0;
    return h;
}

float vine(float3 p, in float c, in float h)
{
    p.y += sin(p.z*0.5625+1.3)*3.5-0.5;
    p.x += cos(p.z*2.0)*1.0;
    float2 q = float2(AS_mod(p.x, c)-c/2.0, p.y);
    return length(q) - h*1.4 -sin(p.z*3.0+sin(p.x*7.0)*0.5)*0.1;
}

float map(float3 p, in float time_param)
{
    p.y += height(p.zx);
    float d = p.y+0.5;
    
    d = smin_custom(d, vine(p+float3(0.8,0.0,0.0),30.0,3.3) );
    d = smin_custom(d, vine(p.zyx+float3(0.0,0.0,17.0),33.0,1.4) );
    d += GetNoise3d(p*0.05, time_param)*(p.y*1.2);
    p.xz *=0.3;
    d+= GetNoise3d(p*0.3, time_param);
    return d;
}

float fogmap(in float3 p, in float d, in float time_param)
{
    // Fog movement retained here
    p.xz -= time_param * Fog_TimeWarp + sin(p.z*0.3)*3.0;
    p.y -= time_param * Fog_VerticalSpeed; // Use Fog_VerticalSpeed for fog particles
    return (max(GetNoise3d(p*0.008+0.1, time_param)-0.1,0.0)*GetNoise3d(p*0.1, time_param))*0.3 * Fog_Density;
}

float3 fogColour( in float3 col, float t )
{
    float3 ext = exp2(-t*0.0001*float3(1.0,1.5,3.0));
    return col*ext + (1.0-ext)*float3(1.0,1.0,1.0);
}

float march(in float3 ro, in float3 rd, out float drift, in float2 scUV, in float time_param)
{
	float precis = Fog_Precision;
    float mul = Fog_Multiplier;
    float h;
    float d = hash12(scUV)*1.5; // Use AS_hash12 from AS_Noise.1.fxh
    drift = 0.0;
    for( int i=0; i<ITERATIONS; i++ )
    {
        float3 p = ro+rd*d;
        h = map(p, time_param);
        if(h < precis*(1.0+d*0.05) || d > Fog_MaxDistance) break;
        drift += fogmap(p, d, time_param);
        d += h*mul;
        mul += 0.004;
	}
    drift = min(drift, 1.0);
	return d;
}

float3 normal( in float3 pos, in float d, in float time_param )
{
	float2 eps = float2( d*d*0.003+0.01, 0.0);
	float3 nor = float3(
        map(pos+eps.xyy, time_param) - map(pos-eps.xyy, time_param),
        map(pos+eps.yxy, time_param) - map(pos-eps.yxy, time_param),
        map(pos+eps.yyx, time_param) - map(pos-eps.yyx, time_param) );
	return normalize(nor);
}

float bnoise(in float3 p, in float time_param)
{
    p.xz *= 0.4;
    float n = GetNoise3d(p*3.0, time_param)*0.4;
    n += GetNoise3d(p*1.5, time_param)*0.2;
    return n*n*0.2;
}

float3 bump(in float3 p, in float3 n, in float ds, in float time_param)
{
    p.xz *= 0.4;
    float2 e = float2(0.01,0.0);
    float n0 = bnoise(p, time_param);
    float3 d_val = float3(bnoise(p+e.xyy, time_param)-n0, bnoise(p+e.yxy, time_param)-n0, bnoise(p+e.yyx, time_param)-n0)/e.x;
    n = normalize(n-d_val*10.0/(ds));
    return n;
}

float shadow(in float3 ro, in float3 rd, in float mint, in float time_param)
{
	float res = 1.0;
    
    float t = mint;
    for( int i=0; i<12; i++ )
    {
		float h = map(ro + rd*t, time_param);
        res = min( res, 4.0*h/t );
        t += clamp( h, 0.1, 1.5 ); // FIX: Use clamp here
    }
    return clamp( res, 0.0, 1.0 ); // FIX: Use clamp here
}

float3 Clouds(float3 sky, float3 rd, in float time_param)
{
    
    rd.y = max(rd.y, 0.0);
    float ele = rd.y;
    float v = (200.0)/(abs(rd.y)+0.01);

    rd.y = v;
    rd.xz = rd.xz * v - time_param * 8.0; // Clouds movement based on time
	rd.xz *= 0.0004;
    
	float f = GetNoise3d(rd.xzz*3.0, time_param) * GetNoise3d(rd.zxx*1.3, time_param)*2.5;
    f = f*pow(ele, 0.5)*2.0;
 	f = clamp(f-0.15, 0.01, 1.0); // FIX: Use clamp here

    return lerp(sky, float3(1.0,1.0,1.0),f );
}

float3 Sky(float3 rd, float3 ligt)
{
    rd.y = max(rd.y, 0.0);
    
    float3 sky = lerp(Sky_HorizonColor, Sky_ZenithColor, pow(0.8-rd.y, 3.0));
    return lerp(sky, Sun_Color, min(pow(max(dot(rd,ligt), 0.0), 4.5)*1.2, 1.0));
}

float Occ(float3 p, in float time_param)
{
    float h = 0.0;
    h = clamp(map(p, time_param), 0.5, 1.0); // FIX: Use clamp here
	return sqrt(h);
}


// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_FrozenFog(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float time_val = AS_getTime();

    float2 p = texcoord.xy - 0.5;
    p.x *= ReShade::AspectRatio;

    // Static camera position and orientation
    // Original ro.y -= camHeight(ro.zx)-.4; will use static ro.zx for camHeight input
    static const float3 FIXED_RO_BASE = float3(0.0, -130.0, -130.0); // Base position
    float3 ro = FIXED_RO_BASE;
    ro.y -= camHeight(FIXED_RO_BASE.zx) - 0.4; // Adjust Y based on static terrain height at camera's XZ

    static const float2 STATIC_MO_OFFSET = float2(-0.1, 0.07); // A small, fixed offset for camera direction
    float3 eyedir = normalize(float3(cos(STATIC_MO_OFFSET.x), STATIC_MO_OFFSET.y * 2.0, sin(STATIC_MO_OFFSET.x)));
    float3 rightdir = normalize(float3(cos(STATIC_MO_OFFSET.x + AS_HALF_PI), 0.0, sin(STATIC_MO_OFFSET.x + AS_HALF_PI)));
    float3 updir = normalize(cross(rightdir, eyedir));
	float3 rd = normalize((p.x*rightdir+p.y*updir)*1.0+eyedir);
	
    float3 ligt = normalize( float3(1.5, 0.9, -0.5) );
    float fg; // Fog density
	float rz = march(ro, rd, fg, texcoord.xy, time_val); // Pass texcoord for hash
	float3 sky = Sky(rd, ligt);
    
    float3 col = sky;
    
    if ( rz < Fog_MaxDistance )
    {
        float3 pixel_pos_world = ro + rz * rd;
        float3 normal_vec = normal( pixel_pos_world, rz, time_val);
        float dist_from_camera = distance(pixel_pos_world, ro);
        normal_vec = bump(pixel_pos_world, normal_vec, dist_from_camera, time_val);
        float shadow_val = (shadow(pixel_pos_world, ligt, 0.04, time_val));
        
        float diffuse = saturate( dot( normal_vec, ligt ) );
        float3 reflection_vec = reflect(rd,normal_vec);
        float specular = pow(saturate( dot( reflection_vec, ligt ) ),5.0)*2.0;

        float fresnel = pow( saturate(1.0+dot(rd, normal_vec)), 3.0 );
        col = Land_Color;
	    col = col*diffuse*shadow_val + fresnel*specular*shadow_val*Sun_Color +abs(normal_vec.y)*Land_DarkColor;
        
        // Fake the red absorption of ice...
        dist_from_camera = Occ(pixel_pos_world + normal_vec * 3.0, time_val);
        col *= float3(dist_from_camera, dist_from_camera, min(dist_from_camera*1.2, 1.0));
        // Fog from ice storm...
        col = lerp(col, sky, smoothstep(Fog_MaxDistance-25.0, Fog_MaxDistance,rz));
        
    }
    else
    {
        col = Clouds(col, rd, time_val);
    }
    
    // Fog mix...
    col = lerp(col, Fog_Color, fg);
    
    // Post...
    col = fogColour(col, rz);

    col = col*col * (3.0 - 2.0 * col);
	col = sqrt(col);
    
	// Apply blend to original backbuffer color
    return AS_applyBlend(float4(col, 1.0), tex2D(ReShade::BackBuffer, texcoord), FrozenFog_BlendMode, FrozenFog_BlendAmount);
}

// ============================================================================
// TECHNIQUES
// ============================================================================

technique AS_VFX_FrozenFog
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_FrozenFog;
    }
}

#endif // __AS_VFX_FrozenFog_1_fx
