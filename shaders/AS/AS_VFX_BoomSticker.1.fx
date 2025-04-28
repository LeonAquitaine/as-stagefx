/*
 * AS_VFX_BoomSticker.1.fx - Simple sticker texture overlay with audio reactivity
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Displays a texture ("sticker") with controls for placement, scale, rotation, and audio reactivity.
 *
 * FEATURES:
 * - Simple texture overlay with position, scale, and rotation controls
 * - Audio reactivity for opacity and scale
 * - Customizable depth masking
 * - Support for custom texture via preprocessor definition
 *
 * USAGE:
 * To use a custom texture, add these lines to your "PreprocessorDefinitions.h" file:
 * #define BoomSticker1_FileName "path/to/your/texture.png"
 * #define BoomSticker1_Width 1920
 * #define BoomSticker1_Height 1080
 *
 * ===================================================================================
 */

// Default texture if not defined by the user
#ifndef BoomSticker1_FileName
    #define BoomSticker1_FileName "LayerStage.png"
#endif

// Default texture dimensions if not defined by the user
#ifndef BoomSticker1_Width
    #define BoomSticker1_Width BUFFER_WIDTH
#endif

#ifndef BoomSticker1_Height
    #define BoomSticker1_Height BUFFER_HEIGHT
#endif

#include "AS_Utils.1.fxh"

// --- Helper Functions ---
float2 rotateUV(float2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float2 center = float2(0.5, 0.5);
    uv -= center;
    float2 rotated = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    return rotated + center;
}

// Main sticker texture and sampler
texture BoomSticker_Texture <source=BoomSticker1_FileName;> { Width = BoomSticker1_Width; Height = BoomSticker1_Height; Format=RGBA8; };
sampler BoomSticker_Sampler { Texture = BoomSticker_Texture; };

// Appearance Controls
uniform float BoomSticker_Opacity < 
    ui_category = "Appearance";
    ui_label = "Opacity";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float BoomSticker_Scale < 
    ui_category = "Appearance";
    ui_label = "Scale";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float2 BoomSticker_ScaleXY < 
    ui_category = "Appearance";
    ui_label = "Scale XY";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 5.0;
    ui_step = 0.001;
> = float2(1.0, 1.0);

uniform float2 BoomSticker_PosXY < 
    ui_category = "Appearance";
    ui_label = "Position";
    ui_type = "slider";
    ui_min = -2.0;
    ui_max = 2.0;
    ui_step = 0.001;
> = float2(0.5, 0.5);

uniform int BoomSticker_SnapRotate < 
    ui_category = "Appearance";
    ui_label = "Snap Rotation";
    ui_type = "slider";
    ui_min = -4;
    ui_max = 4;
    ui_step = 1;
    ui_tooltip = "Snap rotation in 45 degree steps (-180 to 180)";
> = 0;

uniform float BoomSticker_Rotate < 
    ui_category = "Appearance";
    ui_label = "Fine Rotation";
    ui_type = "slider";
    ui_min = -90.0;
    ui_max = 90.0;
    ui_step = 0.01;
> = 0.0;

// Position Controls
AS_STAGEDEPTH_UI(BoomSticker_Depth, "Effect Depth", "Stage Distance")

// Animation Controls
// Add standardized Sway controls (non-audio reactive)
AS_SWAYSPEED_UI(BoomSticker_SwaySpeed, "Animation")
AS_SWAYANGLE_UI(BoomSticker_SwayAngle, "Animation")

// Audio Reactivity Controls
uniform int BoomSticker_AudioAffect < 
    ui_type = "combo";
    ui_label = "Audio Affects";
    ui_items = "Opacity\0Scale\0";
    ui_category = "Audio Reactivity";
> = 0;

// Use the standard AS_AUDIO_SOURCE_UI macro to select audio source
AS_AUDIO_SOURCE_UI(BoomSticker_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(BoomSticker_AudioIntensity, "Audio Intensity", 0.5, 2.0, "Audio Reactivity")

// Debug Controls
uniform int DebugMode < 
    ui_type = "combo";
    ui_label = "Debug View";
    ui_items = "Off\0Beat\0Depth\0Audio Source\0";
    ui_category = "Debug";
> = 0;

//--------------------------------------------------------------------------
// Main pixel shader implementation
//--------------------------------------------------------------------------
void PS_BoomSticker(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    // Get original pixel color first
    float4 originalColor = tex2D(ReShade::BackBuffer, texCoord);
    
    // Handle debug modes
    if (DebugMode == 1) {
        // Debug audio beat
        float beat = Listeningway_Beat;
        passColor = float4(beat, beat, beat, 1.0);
        return;
    }
    else if (DebugMode == 2) {
        // Debug depth visualization
        float depth = ReShade::GetLinearizedDepth(texCoord);
        passColor = float4(depth.xxx, 1.0);
        return;
    }
    else if (DebugMode == 3) {
        // Debug selected audio source
        
        float audioValue = AS_getAudioSource(BoomSticker_AudioSource);


        // Direct access to Listeningway values based on selected source
        
        passColor = float4(audioValue, audioValue, audioValue, 1.0);
        return;
    }
    
    // Standard depth handling as per AS_CodeStandards.md
    float sceneDepth = ReShade::GetLinearizedDepth(texCoord);
    
    // If the scene depth is less than the effect depth, return original color
    // Using a small offset to prevent z-fighting
    if (sceneDepth < BoomSticker_Depth - 0.0005) {
        passColor = originalColor;
        return;
    }
    
    // Apply audio reactivity using standardized AS_Utils function
    float opacity = BoomSticker_Opacity;
    float scale = BoomSticker_Scale;
    
    // Get the raw audio value without scaling it by a base value
    float audioSourceValue = AS_getAudioSource(BoomSticker_AudioSource);
    float audioValue = audioSourceValue * BoomSticker_AudioIntensity;
    
    // Apply the audio to the selected parameter - properly additive
    if (BoomSticker_AudioAffect == 0) {
        opacity = opacity + audioValue;
    }
    else if (BoomSticker_AudioAffect == 1) {
        scale = scale + audioValue;
    }
    
    // Safety clamp
    scale = max(scale, 0.01);
    opacity = saturate(opacity);
    
    // Setup transformation variables
    float3 pivot = float3(0.5, 0.5, 0.0);
    float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
    float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
    float3 mulUV = float3(texCoord.x, texCoord.y, 1);
    
    // Calculate texture aspect ratio correction
    float textureAspect = float(BoomSticker1_Width) / float(BoomSticker1_Height);
    float screenAspect = float(BUFFER_WIDTH) / float(BUFFER_HEIGHT);
    float aspectCorrection = textureAspect / screenAspect;
    
    // Calculate scale with aspect ratio preservation
    float2 ScaleSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * scale / BUFFER_SCREEN_SIZE;
    // Apply aspect ratio correction to maintain texture proportions
    ScaleSize.x *= aspectCorrection;
    float ScaleX = ScaleSize.x * AspectX * BoomSticker_ScaleXY.x;
    float ScaleY = ScaleSize.y * AspectY * BoomSticker_ScaleXY.y;
    
    // Calculate rotation
    float SnapAngle = float(BoomSticker_SnapRotate) * 45.0;
    float Rotate = (BoomSticker_Rotate + SnapAngle) * (AS_PI / 180.0);
    
    // Apply standard non-audio-reactive sway
    // Note: AS_applySway already returns the angle in radians, no need to convert
    float sway = AS_applySway(BoomSticker_SwayAngle, BoomSticker_SwaySpeed);
    
    // Add sway to rotation (sway is already in radians)
    Rotate += sway;
    
    // Build transformation matrices
    float3x3 positionMatrix = float3x3(
        1, 0, 0,
        0, 1, 0,
        -BoomSticker_PosXY.x, -BoomSticker_PosXY.y, 1
    );
    
    float3x3 scaleMatrix = float3x3(
        1/ScaleX, 0, 0,
        0, 1/ScaleY, 0,
        0, 0, 1
    );
    
    float3x3 rotateMatrix = float3x3(
        (cos(Rotate) * AspectX), (sin(Rotate) * AspectX), 0,
        (-sin(Rotate) * AspectY), (cos(Rotate) * AspectY), 0,
        0, 0, 1
    );
    
    // Apply transformations
    float3 SumUV = mul(mul(mul(mulUV, positionMatrix), rotateMatrix), scaleMatrix);
    
    // Sample the sticker texture and apply it only if we're within its bounds
    float4 stickerColor = tex2D(BoomSticker_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));
    
    // Mix with background based on opacity and sticker alpha
    passColor.rgb = lerp(originalColor.rgb, stickerColor.rgb, stickerColor.a * opacity);
    passColor.a = originalColor.a;
}

// Technique definition
technique AS_BoomSticker <
    ui_label = "[AS] VFX: BoomSticker";
    ui_tooltip = "Simple overlay sticker with audio reactivity";
>
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_BoomSticker;
    }
}