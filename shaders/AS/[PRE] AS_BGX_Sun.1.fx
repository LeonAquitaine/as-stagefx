#include "ReShade.fxh" // Standard ReShade header for ScreenSize, Timer, PostProcessVS
#include "AS_Utils.1.fxh" // Custom header for AS utilities
#include "AS_Palette.1.fxh" // Color palette system for AS shaders

// Minimal namespace for this translated shader
namespace TranslatedGLSL {

    // Your existing constants
    static const float ALPHA_EPSILON = 0.00001f;
    static const float CENTER_COORD = 0.5f;
    static const float PERCENT_TO_NORMAL = 0.01f; 
    static const float FULL_OPACITY = 1.0f;
    static const float3 BLACK_COLOR = float3(0.0, 0.0, 0.0);
    // ... (other constants you have)


//------------------------------------------------------------------------------------------------
// Artistic Control Uniforms
//------------------------------------------------------------------------------------------------
uniform float AnimationSpeed <
    ui_type = "slider"; ui_label = "Animation Speed";
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.01;
    ui_tooltip = "Controls the speed of the internal animation.";
    ui_category = "Artistic Controls"; 
> = 1.0;

uniform int QualityIterations <
    ui_type = "slider"; ui_label = "Quality / Iterations";
    ui_min = 20; ui_max = 250; ui_step = 1; 
    ui_tooltip = "Number of iterations for effect generation. Higher is more detailed but slower.";
    ui_category = "Artistic Controls";
> = 100;

uniform float3 EmissionColor <
    ui_type = "color"; ui_label = "Emission Color Weights";
    ui_tooltip = "RGB weights for color accumulation. Original (4,2,1) gives fiery look.";
    ui_category = "Artistic Controls";
> = float3(4.0f, 2.0f, 1.0f);

uniform float FocalRadius <
    ui_type = "slider"; ui_label = "Focal Radius";
    ui_min = 0.1; ui_max = 15.0; ui_step = 0.1; 
    ui_tooltip = "The radius around which the s_step function creates a feature.";
    ui_category = "Artistic Controls";
> = 5.0;

uniform float FocalStrength <
    ui_type = "slider"; ui_label = "Focal Strength";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_tooltip = "How strongly the distance from Focal Radius affects the step size.";
    ui_category = "Artistic Controls";
> = 0.3;

uniform float FocalSmoothness <
    ui_type = "slider"; ui_label = "Focal Feature Smoothness";
    ui_min = 0.001; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Controls the smoothness of the feature at the Focal Radius. Smaller values = sharper; larger values = softer, broader feature.";
    ui_category = "Artistic Controls";
> = 0.1; // Default smoothness

uniform float CoreBrightness < 
    ui_type = "slider"; ui_label = "Core Brightness / Exposure";
    ui_min = 0.1; ui_max = 50.0; ui_step = 0.1; 
    ui_tooltip = "Overall brightness adjustment before final tonemapping compression.";
    ui_category = "Artistic Controls";
> = 6.0;

uniform float CenterVignettePower < 
    ui_type = "slider"; ui_label = "Center Vignette Power";
    ui_min = 0.0; ui_max = 2.5; ui_step = 0.01;
    ui_tooltip = "Power for the radial vignette (dot(u,u) term). 0.0 = no radial vignette from u; 1.0 = original strength.";
    ui_category = "Artistic Controls";
> = 1.0;

uniform float DetailFrequency < 
    ui_type = "slider"; ui_label = "Detail Frequency";
    ui_min = 1.0; ui_max = 64.0; ui_step = 0.5;
    ui_tooltip = "Frequency multiplier in the detail perturbation loop.";
    ui_category = "Artistic Controls";
> = 16.0;

uniform float DetailAmount < 
    ui_type = "slider"; ui_label = "Detail Amount";
    ui_min = 0.0; ui_max = 0.1; ui_step = 0.0005; 
    ui_tooltip = "Amount/strength of detail added in the perturbation loop.";
    ui_category = "Artistic Controls";
> = 0.01;

//------------------------------------------------------------------------------------------------
// Palette & Style
//------------------------------------------------------------------------------------------------
uniform bool UseOriginalColors <
    ui_label = "Use Original Color Weights";
    ui_tooltip = "When enabled, uses the original RGB weight emission colors. When disabled, uses palettes.";
    ui_category = "Palette & Style";
> = true;

uniform float OriginalColorIntensity <
    ui_type = "slider"; ui_label = "Original Color Intensity";
    ui_min = 0.1; ui_max = 5.0; ui_step = 0.01;
    ui_tooltip = "Adjusts the intensity of the original colors when enabled.";
    ui_category = "Palette & Style";
    ui_spacing = 0;
> = 1.0;

uniform float OriginalColorSaturation <
    ui_type = "slider"; ui_label = "Original Color Saturation";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_tooltip = "Adjusts the saturation of original colors when enabled.";
    ui_category = "Palette & Style";
> = 1.0;

AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_FIRE, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(Sun_, "Palette & Style")

uniform float ColorCycleSpeed <
    ui_type = "slider"; ui_label = "Color Cycle Speed";
    ui_tooltip = "Controls how fast palette colors cycle. 0 = static.";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.1;
    ui_category = "Palette & Style";
> = 0.1;

uniform float PaletteColorIntensity <
    ui_type = "slider"; ui_label = "Palette Color Intensity";
    ui_min = 0.1; ui_max = 5.0; ui_step = 0.1;
    ui_tooltip = "Intensity multiplier for palette colors.";
    ui_category = "Palette & Style";
> = 1.0;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Show Color Intensity\0Show Palette Position\0")

// --- Stage/Position ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(Position, Scale)

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(Sun_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Sun_AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int Sun_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Focal Radius\0Detail Frequency\0Core Brightness\0"; ui_category = "Audio Reactivity"; > = 0;

    // Main Pixel Shader, equivalent to mainImage in GLSL
    float4 MinimalPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
    {
        float4 o = float4(0.0f, 0.0f, 0.0f, 0.0f); 
        float i = 0.0f; 
        float d = 0.0f; 
        float s;
        
        // Get original pixel color for blending and depth check
        float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
        float depth = ReShade::GetLinearizedDepth(texcoord);
        
        // Apply depth test - skip effect if pixel is closer than effect depth
        if (depth < EffectDepth) {
            return originalColor;
        }

        // Apply audio reactivity to selected parameters
        float animSpeed = AnimationSpeed;
        float focalRad = FocalRadius;
        float detailFreq = DetailFrequency;
        float coreBright = CoreBrightness;
        
        float audioReactivity = AS_applyAudioReactivity(1.0, Sun_AudioSource, Sun_AudioMultiplier, true);
        
        // Map audio target combo index to parameter adjustment
        if (Sun_AudioTarget == 1) animSpeed *= audioReactivity;
        else if (Sun_AudioTarget == 2) focalRad *= audioReactivity;
        else if (Sun_AudioTarget == 3) detailFreq *= audioReactivity;
        else if (Sun_AudioTarget == 4) coreBright *= audioReactivity;
        
        // --- POSITION HANDLING ---
        // Step 1: Center and correct for aspect ratio
        float2 p_centered = (texcoord - AS_HALF) * 2.0;          // Center coordinates (-1 to 1)
        p_centered.x *= ReShade::AspectRatio;                    // Correct for aspect ratio
        
        // Step 2: Apply rotation around center (negative rotation for clockwise)
        float sinRot, cosRot;
        float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
        sincos(-rotationRadians, sinRot, cosRot);
        float2 p_rotated = float2(
            p_centered.x * cosRot - p_centered.y * sinRot,
            p_centered.x * sinRot + p_centered.y * cosRot
        );
        
        // Step 3: Apply position and scale
        float2 u = p_rotated / Scale - Position;

        float base_min_step_size = 0.04f; // This could also be a uniform if desired

        for (i = 0.0f; i < QualityIterations; i++) 
        {
            float3 p_current = float3(u * d, d);
            float s_inner = 0.15f; 
            while (s_inner < 1.0f)
            {
                float3 detail_vec = float3(DetailAmount, DetailAmount, DetailAmount); 
                float3 cos_arg = (AS_getTime() * animSpeed) + p_current.z + p_current * s_inner * detailFreq; 
                float3 cos_val = cos(cos_arg);
                float dot_val = dot(cos_val, detail_vec);
                p_current += abs(dot_val) / (s_inner + ALPHA_EPSILON); 
                s_inner *= 1.4f; 
            }

            float current_length_p_xy = length(p_current.xy);
            // MODIFIED s_step calculation with FocalSmoothness
            float value_diff_from_radius = focalRad - current_length_p_xy;
            float smoothed_abs_diff = sqrt(value_diff_from_radius * value_diff_from_radius + FocalSmoothness * FocalSmoothness);
            float s_step = base_min_step_size + smoothed_abs_diff * FocalStrength;
            
            d += s_step;
            
            if (s_step > ALPHA_EPSILON) 
            {
                o += float4(EmissionColor, 0.0f) / s_step; 
            }
        }

        float dot_u_u = dot(u, u);
        float effective_dot_u_u_divisor = pow(dot_u_u + ALPHA_EPSILON, CenterVignettePower); 
        if (abs(effective_dot_u_u_divisor) < ALPHA_EPSILON) 
        {
            effective_dot_u_u_divisor = ALPHA_EPSILON * sign(effective_dot_u_u_divisor + ALPHA_EPSILON); // ensure sign is preserved if it was negative, though pow should make it positive if base is positive
        }
        
        float4 o_squared = o * o; 
        float4 tonemap_arg = (o_squared / 20000000.0f / effective_dot_u_u_divisor) * coreBright; 
        
        // Apply the color palette if enabled
        float3 final_color;
        if (UseOriginalColors) {
            // Original color approach using EmissionColor components as weights
            final_color = tanh(tonemap_arg.rgb);
            
            // Apply intensity and saturation adjustments
            final_color *= OriginalColorIntensity;
            
            // Apply saturation adjustment
            float luma = dot(final_color, float3(0.299, 0.587, 0.114));
            final_color = lerp(float3(luma, luma, luma), final_color, OriginalColorSaturation);
        } else {
            // Use palette-based coloring
            // Get a normalized intensity value from the overall brightness
            float intensity = length(tonemap_arg.rgb) / sqrt(3.0);
            intensity = saturate(intensity); // Ensure in [0,1] range
            
            // Apply optional color cycling
            float t = intensity;
            if (ColorCycleSpeed != 0.0) {
                float cycleRate = ColorCycleSpeed * 0.1;
                t = frac(t + cycleRate * AS_getTime());
            }
            
            // Get color from palette system
            if (PalettePreset == AS_PALETTE_CUSTOM) {
                final_color = AS_GET_INTERPOLATED_CUSTOM_COLOR(Sun_, t);
            } else {
                final_color = AS_getInterpolatedColor(PalettePreset, t);
            }
            
            // Apply intensity control
            final_color *= PaletteColorIntensity * intensity;
        }
        
        // Create the effect color with alpha
        float4 effectColor = float4(final_color, 1.0f);
        
        // Apply blend mode and strength
        float4 finalColor = float4(AS_ApplyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0);
        finalColor = lerp(originalColor, finalColor, BlendStrength);
          // Show debug overlay if enabled
        if (DebugMode != AS_DEBUG_OFF) {
            float4 debugMask = float4(0, 0, 0, 0);
            
            if (DebugMode == 1) { // Show Color Intensity
                float intensityVal = length(tonemap_arg.rgb) / sqrt(3.0);
                debugMask = float4(intensityVal, intensityVal, intensityVal, 1.0);
            }
            else if (DebugMode == 2) { // Show Palette Position
                float t = length(tonemap_arg.rgb) / sqrt(3.0);
                if (ColorCycleSpeed != 0.0) {
                    float cycleRate = ColorCycleSpeed * 0.1;
                    t = frac(t + cycleRate * AS_getTime());
                }
                debugMask = float4(t, t, t, 1.0);
            }
            
            // Display debug info in top-left corner
            float debugSize = 0.15;
            float2 debugPos = float2(0.05, 0.05);
            if (all(abs(texcoord - debugPos) < debugSize)) {
                // Add audio reactivity overlay
                if (Sun_AudioTarget != 0) {
                    debugMask.r = audioReactivity;
                }
                return debugMask;
            }
        }
        
        return finalColor;
    }

    // Technique definition
    technique MinimalTranslatedShader_Artistic_Tech < 
        ui_label = "[AS] BGX: Sun"; // Updated Label
        ui_tooltip = "Dynamic sun/star effect with outward radiating energy, featuring customizable colors and smooth focal features.";
    >
    {
        pass
        {
            VertexShader = PostProcessVS; 
            PixelShader = MinimalPS;
        }
    }

} // end namespace TranslatedGLSL