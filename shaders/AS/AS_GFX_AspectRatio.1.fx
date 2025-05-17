/**
 * AS_GFX_AspectRatio.1.fx - Aspect Ratio Framing Tool
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A versatile aspect ratio framing tool designed to help position subjects for social media posts,
 * photography, and video composition. Creates customizable aspect ratio frames with optional guides.
 * Features comprehensive composition guides for professional photography and cinematography.
 *
 * FEATURES:
 * - Preset aspect ratios for common social media, photography, and video formats
 *   - Each aspect ratio available in both landscape and portrait orientations
 *   - Platform-specific tags (FB, IG, YT, etc.) for quick identification
 * - Custom aspect ratio input option
 * - Adjustable clipped area color and opacity
 * - Advanced composition guides:
 *   - Rule of Thirds, Golden Ratio, Center Lines
 *   - Diagonal Method (Baroque and Sinister diagonals)
 *   - Harmonic Armature / Dynamic Symmetry Grid
 *   - Phi Grid (Golden Grid)
 *   - Golden Spiral with four orientation options
 *   - Triangle composition guides
 *   - Customizable grid overlays
 *   - Safe zones for video production
 * - Adjustable guide intensity, width, and rotation
 * - Horizontal/vertical alignment controls
 * - Optimized for all screen resolutions
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. User selects a preset aspect ratio or defines a custom ratio
 * 2. Shader calculates the appropriate frame dimensions based on screen resolution
 * 3. Areas outside the selected aspect ratio are filled with customizable color/opacity
 * 4. Optional composition guides are drawn to assist with subject positioning
 * 5. Advanced pattern controls allow for rotation and customization of guide elements
 * 6. Result is blended with the original image for a non-destructive guide
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_AspectRatio_1_fx
#define __AS_GFX_AspectRatio_1_fx

// Core includes
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
#define GOLDEN_RATIO 1.6180339887
#define AS_PI 3.14159265359
#define AS_TWO_PI 6.28318530718

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Aspect Ratio Selection
uniform int AspectRatioPreset < 
    ui_type = "combo";    ui_label = "Aspect Ratio Preset";
    ui_tooltip = "Select from common aspect ratios or choose 'Custom' to define your own";
    ui_category = "Aspect Ratio";    ui_items = "Custom\0"               "Eorzea Collection\0"
               "  [EC] Standard Image (3:5 Portrait)\0"
               "  [EC] Standard Image (5:3 Landscape)\0"
               "  [EC] Layout 2 - Main Image (104:57)\0"
               "  [EC] Layout 3 - Grid Image (103:56)\0"
               "  [EC] Layout 4 - Wide Image (123:50)\0"
               "  [EC] Layout 5 - Thumbnail (85:70)\0"
               "  [EC] Layout 6 - Center Image (115:95)\0"               "BlueSky\0"
               "  [BS] Post Image (Square 1:1)\0"
               "  [BS] Post Image (1.91:1 Landscape)\0"
               "  [BS] Post Image (4:5 Portrait)\0" 
               "  [BS] Post Image (5:4 Landscape)\0"
               "  [BS] Profile Picture (1:1)\0"
               "  [BS] Banner Image (3:1)\0"               "Instagram\0"
               "  [IG] Feed Post (Square 1:1)\0"
               "  [IG] Feed Post (4:5 Portrait)\0"
               "  [IG] Feed Post (5:4 Landscape)\0"
               "  [IG] Feed Post (1.91:1 Landscape)\0"
               "  [IG] Story / Reels (9:16 Portrait)\0"
               "  [IG] Story / Reels (16:9 Landscape)\0"               "Facebook\0"
               "  [FB] Feed Post (1.91:1 Landscape)\0"
               "  [FB] Feed Post (4:5 Portrait)\0"
               "  [FB] Feed Post (5:4 Landscape)\0"
               "  [FB] Story (9:16 Portrait)\0"
               "  [FB] Story (16:9 Landscape)\0"
               "  [FB] Cover Photo (2.63:1 Landscape)\0"               "Twitter (X)\0"
               "  [TW] Single Image (16:9 Landscape)\0"
               "  [TW] Single Image (9:16 Portrait)\0"
               "  [TW] Multi-Image 2 Images (7:8 Portrait)\0"
               "  [TW] Multi-Image 2 Images (8:7 Landscape)\0"
               "  [TW] Multi-Image 4 Images (2:1 Landscape)\0"               
               "LinkedIn\0"
               "  [LI] Feed Post (1.91:1 Landscape)\0"
               "  [LI] Story (9:16 Portrait)\0"
               "  [LI] Story (16:9 Landscape)\0"               
               "Pinterest\0"
               "  [PI] Pin (2:3 Portrait)\0"
               "  [PI] Pin (3:2 Landscape)\0"
               "  [PI] Max Length Pin (1:2.1 Portrait)\0"
               "  [PI] Max Length Pin (2.1:1 Landscape)\0"               "TikTok / Snapchat\0"
               "  [TS] Video / Story (9:16 Portrait)\0"
               "  [TS] Video / Story (16:9 Landscape)\0"
               "YouTube\0"
               "  [YT] Thumbnail (16:9 Landscape)\0"
               "  [YT] Shorts (9:16 Portrait)\0"
               "  [YT] Community Post (1:1)\0"
               "Photography\0"
               "  [PH] 3:2 (Classic)\0"
               "  [PH] 4:3 (Standard)\0"
               "  [PH] 5:4 (Medium Format)\0"
               "  [PH] 1:1 (Square)\0"
               "Cinema\0"
               "  [CM] 16:9 (HD/4K)\0"
               "  [CM] 21:9 (Ultrawide)\0"
               "  [CM] 2.39:1 (Anamorphic)\0";
> = 0;

uniform float2 CustomAspectRatio <
    ui_type = "drag";
    ui_label = "Custom Aspect Ratio";
    ui_tooltip = "Set your own aspect ratio (X:Y)";
    ui_category = "Aspect Ratio";
    ui_min = 0.1; ui_max = 10.0;
    ui_step = 0.01;
> = float2(16.0, 9.0);

// Guides and Grid Options
uniform int GuideType <
    ui_type = "combo";
    ui_label = "Composition Guide";
    ui_tooltip = "Optional grid overlay to help with composition";
    ui_category = "Composition Guides";
    ui_items = "None\0"
               "Basic Guides\0"
               "  Rule of Thirds\0"
               "  Golden Ratio\0"
               "  Center Lines\0"
               "  Phi Grid (Golden Grid)\0"
               "Dynamic Guides\0"
               "  Diagonal Method - Both\0"
               "  Diagonal Method - Baroque\0"
               "  Diagonal Method - Sinister\0"
               "  Triangle - Up\0"
               "  Triangle - Down\0"
               "  Triangle - Diagonal\0"
               "  Golden Spiral - Lower Right\0"
               "  Golden Spiral - Upper Right\0"
               "  Golden Spiral - Upper Left\0"
               "  Golden Spiral - Lower Left\0"
               "  Harmonic Armature - Basic\0"
               "  Harmonic Armature - Reciprocal\0"
               "  Harmonic Armature - Complex\0"
               "Practical Guides\0"
               "  Grid 3×3\0"
               "  Grid 4×4\0"
               "  Grid 5×5\0"
               "  Grid 6×6\0"
               "  Safe Zones\0";
> = 0;

// Guide type constants (hundreds place = main type, ones place = subtype)
#define GUIDE_NONE 0
#define GUIDE_RULE_THIRDS 100
#define GUIDE_GOLDEN_RATIO 200
#define GUIDE_CENTER_LINES 300
#define GUIDE_DIAGONAL_METHOD 400
#define GUIDE_PHI_GRID 500
#define GUIDE_TRIANGLE 600
#define GUIDE_GOLDEN_SPIRAL 700
#define GUIDE_HARMONIC_ARMATURE 800
#define GUIDE_GRID 900
#define GUIDE_SAFE_ZONES 1000

// Guide subtype constants (add to main type)
#define SUBTYPE_DEFAULT 0
#define SUBTYPE_BAROQUE 1
#define SUBTYPE_SINISTER 2
#define SUBTYPE_UPPER_LEFT 2
#define SUBTYPE_UPPER_RIGHT 1
#define SUBTYPE_LOWER_LEFT 3
#define SUBTYPE_LOWER_RIGHT 0
#define SUBTYPE_UP 0
#define SUBTYPE_DOWN 1
#define SUBTYPE_DIAGONAL 2
#define SUBTYPE_RECIPROCAL 1
#define SUBTYPE_COMPLEX 2

// Array mapping UI indices directly to encoded guide values
static const int GUIDE_MAP[] = {
    GUIDE_NONE,                         // [0] None
    GUIDE_NONE,                         // [1] Basic Guides (header)
    GUIDE_RULE_THIRDS,                  // [2] Rule of Thirds
    GUIDE_GOLDEN_RATIO,                 // [3] Golden Ratio
    GUIDE_CENTER_LINES,                 // [4] Center Lines
    GUIDE_PHI_GRID,                     // [5] Phi Grid (Golden Grid)
    GUIDE_NONE,                         // [6] Dynamic Guides (header)
    GUIDE_DIAGONAL_METHOD,              // [7] Diagonal Method - Both
    GUIDE_DIAGONAL_METHOD + SUBTYPE_BAROQUE,   // [8] Diagonal Method - Baroque
    GUIDE_DIAGONAL_METHOD + SUBTYPE_SINISTER,  // [9] Diagonal Method - Sinister
    GUIDE_TRIANGLE + SUBTYPE_UP,        // [10] Triangle - Up
    GUIDE_TRIANGLE + SUBTYPE_DOWN,      // [11] Triangle - Down
    GUIDE_TRIANGLE + SUBTYPE_DIAGONAL,  // [12] Triangle - Diagonal
    GUIDE_GOLDEN_SPIRAL + SUBTYPE_LOWER_RIGHT, // [13] Golden Spiral - Lower Right
    GUIDE_GOLDEN_SPIRAL + SUBTYPE_UPPER_RIGHT, // [14] Golden Spiral - Upper Right
    GUIDE_GOLDEN_SPIRAL + SUBTYPE_UPPER_LEFT,  // [15] Golden Spiral - Upper Left
    GUIDE_GOLDEN_SPIRAL + SUBTYPE_LOWER_LEFT,  // [16] Golden Spiral - Lower Left
    GUIDE_HARMONIC_ARMATURE,            // [17] Harmonic Armature - Basic
    GUIDE_HARMONIC_ARMATURE + SUBTYPE_RECIPROCAL, // [18] Harmonic Armature - Reciprocal
    GUIDE_HARMONIC_ARMATURE + SUBTYPE_COMPLEX,    // [19] Harmonic Armature - Complex
    GUIDE_NONE,                         // [20] Practical Guides (header)
    GUIDE_GRID,                         // [21] Grid 3×3
    GUIDE_GRID + 1,                     // [22] Grid 4×4
    GUIDE_GRID + 2,                     // [23] Grid 5×5
    GUIDE_GRID + 3,                     // [24] Grid 6×6
    GUIDE_SAFE_ZONES                    // [25] Safe Zones
};

// Helper functions to extract type and subtype from the encoded value
int GetGuideType(int guideValue) {
    return guideValue / 100;
}

int GetGuideSubType(int guideValue) {
    return guideValue % 100;
}

// Simple accessor function that handles boundary checking
int GetGuideValue() {
    // Default to None for invalid indices or headers
    if (GuideType < 0 || GuideType >= 26 || 
        GuideType == 1 || GuideType == 6 || GuideType == 20) {
        return GUIDE_NONE;
    }
    
    return GUIDE_MAP[GuideType];
}

// Appearance Controls
uniform float4 ClippedAreaColor <
    ui_type = "color";
    ui_label = "Masked Area Color";
    ui_tooltip = "Color for areas outside the selected aspect ratio";
    ui_category = "Appearance";
> = float4(0.0, 0.0, 0.0, 0.75);

uniform float4 GuideColor <
    ui_type = "color";
    ui_label = "Guide Color";
    ui_tooltip = "Color for the guide lines";
    ui_category = "Appearance";
> = float4(1.0, 1.0, 1.0, 0.5);

uniform float GuideIntensity <
    ui_type = "drag";
    ui_label = "Guide Intensity";
    ui_tooltip = "Adjusts the opacity of composition guides";
    ui_category = "Appearance";
    ui_min = 0.1; ui_max = 1.0;
    ui_step = 0.05;
> = 1.0;

uniform bool PatternAdvanced <
    ui_label = "Advanced Pattern Controls";
    ui_tooltip = "Enable additional pattern customization";
    ui_category = "Advanced Guide Options";
> = false;

uniform float PatternRotation <
    ui_type = "drag";
    ui_label = "Pattern Rotation";
    ui_tooltip = "Rotate the pattern (in degrees)";
    ui_category = "Advanced Guide Options";
    ui_min = 0.0; ui_max = 360.0;
    ui_step = 0.5;
> = 0.0;

uniform float PatternComplexity <
    ui_type = "drag";
    ui_label = "Pattern Complexity";
    ui_tooltip = "Adjust the complexity of certain patterns";
    ui_category = "Advanced Guide Options";
    ui_category_closed = true;
    ui_min = 1.0; ui_max = 10.0;
    ui_step = 0.1;
> = 3.0;

uniform float GridWidth <
    ui_type = "drag";
    ui_label = "Grid Width";
    ui_tooltip = "Width of grid lines and border (in pixels)";
    ui_category = "Appearance";
    ui_min = 0.0; ui_max = 10.0;
    ui_step = 0.1;
> = 1.0;

// Position Controls
uniform float HorizontalOffset <
    ui_type = "drag";
    ui_label = "Horizontal Position";
    ui_tooltip = "Shift the frame horizontally";
    ui_category = "Position";
    ui_min = -0.5; ui_max = 0.5;
    ui_step = 0.001;
> = 0.0;

uniform float VerticalOffset <
    ui_type = "drag";
    ui_label = "Vertical Position"; 
    ui_tooltip = "Shift the frame vertically";
    ui_category = "Position";
    ui_min = -0.5; ui_max = 0.5;
    ui_step = 0.001;
> = 0.0;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// This array holds all the aspect ratio values indexed by the position in the dropdown
static const float ASPECT_RATIOS[] = {
    0.0,            // [0] Custom (placeholder, actual value calculated from CustomAspectRatio)
    
    // Eorzea Collection
    (57.0/34.0),      // [1] Eorzea Collection (group header) - Standard Image (3:5) [V]
    (57.0/34.0),      // [2] Standard Image (3:5 Portrait)
    (34.0/57.0),      // [3] Standard Image (5:3 Landscape)
    (104.0/57.0),   // [4] Layout 2 - Main Image (104:57)
    (103.0/56.0),   // [5] Layout 3 - Grid Image (103:56) 
    (123.0/50.0),   // [6] Layout 4 - Wide Image (123:50)
    (85.0/70.0),    // [7] Layout 5 - Thumbnail (85:70)
    (115.0/95.0),   // [8] Layout 6 - Center Image (115:95)
      // BlueSky
    1.0,            // [9] BlueSky (group header) - Post Image (Square 1:1)
    1.0,            // [10] Post Image (Square 1:1)
    1.91,           // [11] Post Image (1.91:1 Landscape)
    (5.0/4.0),      // [12] Post Image (4:5 Portrait)
    (4.0/5.0),      // [13] Post Image (5:4 Landscape)
    1.0,            // [14] Profile Picture (1:1)
    3.0,            // [15] Banner Image (3:1)      // Instagram
    1.0,            // [16] Instagram (group header) - Square
    1.0,            // [17] Feed Post Square (1:1)
    (5.0/4.0),      // [18] Feed Post (4:5 Portrait)
    (4.0/5.0),      // [19] Feed Post (5:4 Landscape)
    1.91,           // [20] Feed Post (1.91:1 Landscape)
    (16.0/9.0),     // [21] Story / Reels (9:16 Portrait)
    (9.0/16.0),     // [22] Story / Reels (16:9 Landscape)
      // Facebook
    1.91,           // [23] Facebook (group header) - Feed Post Landscape
    1.91,           // [24] Feed Post (1.91:1 Landscape)
    (5.0/4.0),      // [25] Feed Post (4:5 Portrait)
    (4.0/5.0),      // [26] Feed Post (5:4 Landscape)
    (16.0/9.0),     // [27] Story (9:16 Portrait)
    (9.0/16.0),     // [28] Story (16:9 Landscape)
    2.63,           // [29] Cover Photo (2.63:1 Landscape)
      // Twitter (X)
    (16.0/9.0),     // [30] Twitter (group header) - Single Image 
    (9.0/16.0),     // [31] Single Image (16:9 Landscape)
    (16.0/9.0),     // [32] Single Image (9:16 Portrait)
    (8.0/7.0),      // [33] Multi-Image 2 Images (7:8 Portrait)
    (7.0/8.0),      // [34] Multi-Image 2 Images (8:7 Landscape)
    2.0,            // [35] Multi-Image 4 Images (2:1 Landscape)
      // LinkedIn
    1.91,           // [36] LinkedIn (group header) - Feed Post
    1.91,           // [37] Feed Post (1.91:1 Landscape)
    (16.0/9.0),     // [38] Story (9:16 Portrait)
    (9.0/16.0),     // [39] Story (16:9 Landscape)
    
    // Pinterest
    (3.0/2.0),      // [40] Pinterest (group header) - Pin (2:3) [V]
    (3.0/2.0),      // [41] Pin (2:3 Portrait)
    (2.0/3.0),      // [42] Pin (3:2 Landscape)
    2.1,            // [43] Max Length Pin (1:2.1 Portrait)
    (1.0/2.1),      // [44] Max Length Pin (2.1:1 Landscape)
      // TikTok/Snapchat
    (16.0/9.0),     // [45] TikTok / Snapchat (group header) - Video/Story (9:16) [V]
    (16.0/9.0),     // [46] Video / Story (9:16 Portrait)
    (9.0/16.0),     // [47] Video / Story (16:9 Landscape)
    
    // YouTube
    (16.0/9.0),     // [48] YouTube (group header) - Thumbnail
    (9.0/16.0),     // [49] Thumbnail (16:9 Landscape)
    (16.0/9.0),     // [50] Shorts (9:16 Portrait)
    1.0,            // [51] Community Post (1:1)      // Photography
    (3.0/2.0),      // [52] Photography (group header) - Classic (3:2)
    (3.0/2.0),      // [53] Classic (3:2)
    (4.0/3.0),      // [54] Standard (4:3)
    (5.0/4.0),      // [55] Medium Format (5:4)
    1.0,            // [56] Square (1:1)
    
    // Cinema
    (16.0/9.0),     // [57] Cinema (group header) - HD/4K (16:9)
    (9.0/16.0),     // [58] HD/4K (16:9 Landscape)
    (21.0/9.0),     // [59] Ultrawide (21:9)
    2.39            // [60] Anamorphic (2.39:1)
};

float GetAspectRatio() {
    if (AspectRatioPreset == 0) {
        // Custom aspect ratio
        return CustomAspectRatio.x / CustomAspectRatio.y;
    }
    else {
        return ASPECT_RATIOS[AspectRatioPreset];
    }
}

float2 RotatePoint(float2 pt, float2 center, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    
    // Translate point to origin
    pt -= center;
    
    // Rotate point
    float2 rotated = float2(
        pt.x * c - pt.y * s,
        pt.x * s + pt.y * c
    );
    
    // Translate back
    rotated += center;
    
    return rotated;
}

// Helper function to draw guide line with rotation and intensity support
float3 DrawGuideLine(float3 originalColor, float3 guideColor, float guideAlpha, float2 frameCoord, 
                    float2 lineStart, float2 lineEnd, float2 pixelSize, float lineWidth) {
    // Apply rotation if needed
    if (PatternAdvanced && PatternRotation != 0.0) {
        float2 center = float2(0.5, 0.5);
        lineStart = RotatePoint(lineStart, center, PatternRotation * AS_PI / 180.0);
        lineEnd = RotatePoint(lineEnd, center, PatternRotation * AS_PI / 180.0);
    }
    
    // Calculate distance from point to line
    float2 lineDir = lineEnd - lineStart;
    float lineLength = length(lineDir);
    lineDir /= lineLength; // Normalize
    
    float2 toPoint = frameCoord - lineStart;
    float projLength = dot(toPoint, lineDir);
    
    // Check if projection falls within line segment
    if (projLength >= 0.0 && projLength <= lineLength) {
        float2 closestPoint = lineStart + lineDir * projLength;
        float dist = distance(frameCoord, closestPoint);
          // Adjust line width for consistent physical width regardless of aspect ratio
        float adjustedWidth = pixelSize.y * lineWidth;
        
        if (dist < adjustedWidth) {
            return lerp(originalColor, guideColor, guideAlpha * GuideIntensity);
        }
    }
    
    return originalColor;
}

// Draws the composition guide overlay
float3 DrawGuides(float2 texcoord, float3 originalColor, float3 guideColor, float aspectRatio) {
    float2 borderSize = float2(0.0, 0.0);
    bool isInFrame = true;
    
    // Calculate active frame area based on aspect ratio
    if (aspectRatio > ReShade::AspectRatio) {
        // Wider aspect ratio than screen - black bars on top and bottom
        borderSize.y = (1.0 - (ReShade::AspectRatio / aspectRatio)) / 2.0;
        isInFrame = (texcoord.y >= borderSize.y + VerticalOffset) && 
                   (texcoord.y <= 1.0 - borderSize.y + VerticalOffset);
    }
    else {
        // Taller or equal aspect ratio - black bars on sides
        borderSize.x = (1.0 - (aspectRatio / ReShade::AspectRatio)) / 2.0;
        isInFrame = (texcoord.x >= borderSize.x + HorizontalOffset) && 
                   (texcoord.x <= 1.0 - borderSize.x + HorizontalOffset);
    }    // Get the guide configuration from the UI selection
    int guideValue = GetGuideValue();
    int actualGuideType = GetGuideType(guideValue);
    int actualSubType = GetGuideSubType(guideValue);
    
    // If not in frame, return original color immediately
    if (!isInFrame && actualGuideType != 0) {
        return originalColor;
    }

    // Draw guides
    if (actualGuideType != 0 && isInFrame) {
        // Adjust texture coordinates to the active area
        float2 frameCoord = texcoord;
          if (aspectRatio > ReShade::AspectRatio) {
            // Wider aspect ratio - normalize y coordinates first
            float topEdge = borderSize.y + VerticalOffset;
            float frameHeight = 1.0 - (borderSize.y * 2.0);
            
            // Normalize Y from [topEdge, topEdge + frameHeight] to [0, 1]
            frameCoord.y = (texcoord.y - topEdge) / frameHeight;
            
            // For X, just adjust for horizontal offset, centering in available width
            frameCoord.x = texcoord.x - HorizontalOffset;
        }
        else {
            // Taller aspect ratio - normalize x coordinates first
            float leftEdge = borderSize.x + HorizontalOffset;
            float frameWidth = 1.0 - (borderSize.x * 2.0);
            
            // Normalize X from [leftEdge, leftEdge + frameWidth] to [0, 1]
            frameCoord.x = (texcoord.x - leftEdge) / frameWidth;
            
            // For Y, just adjust for vertical offset, centering in available height
            frameCoord.y = texcoord.y - VerticalOffset;
        }        // Calculate pixel-width based threshold for grid lines with consistent physical width
        float2 pixelSize = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
        
        // Base line width on vertical resolution for consistent physical width
        float gridWidthUniform = pixelSize.y * GridWidth * 0.5; // Half width for each side
        
        // Use the same physical width for both directions
        float gridWidthX = gridWidthUniform;
        float gridWidthY = gridWidthUniform;
        
        // Rule of thirds grid
        if (actualGuideType == 1) { // GUIDE_RULE_THIRDS / 100
            // Vertical lines
            if (abs(frameCoord.x - 1.0/3.0) < gridWidthX || abs(frameCoord.x - 2.0/3.0) < gridWidthX)
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
            
            // Horizontal lines
            if (abs(frameCoord.y - 1.0/3.0) < gridWidthY || abs(frameCoord.y - 2.0/3.0) < gridWidthY)
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
        }
        // Golden ratio
        else if (actualGuideType == 2) { // GUIDE_GOLDEN_RATIO / 100
            float goldenX = 1.0 / GOLDEN_RATIO;
            float goldenY = 1.0 / GOLDEN_RATIO;
              // Vertical lines
            if (abs(frameCoord.x - goldenX) < gridWidthX || abs(frameCoord.x - (1.0 - goldenX)) < gridWidthX)
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
            
            // Horizontal lines
            if (abs(frameCoord.y - goldenY) < gridWidthY || abs(frameCoord.y - (1.0 - goldenY)) < gridWidthY)
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
        }        // Center lines
        else if (actualGuideType == 3) { // GUIDE_CENTER_LINES / 100
            // Vertical center line
            if (abs(frameCoord.x - 0.5) < gridWidthX)
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
            
            // Horizontal center line
            if (abs(frameCoord.y - 0.5) < gridWidthY)
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
        }        // Diagonal Method (Baroque and Sinister Diagonals)
        else if (actualGuideType == 4) { // GUIDE_DIAGONAL_METHOD / 100
            // Diagonal lines from opposite corners
            float diagonalWidth = sqrt(gridWidthX * gridWidthX + gridWidthY * gridWidthY);
            
            // Apply rotation if enabled
            float2 rotatedCoord = frameCoord;
            if (PatternAdvanced && PatternRotation != 0.0) {
                rotatedCoord = RotatePoint(frameCoord, float2(0.5, 0.5), PatternRotation * AS_PI / 180.0);
            }
            
            if (actualSubType == 0 || actualSubType == 1) {
                // Baroque diagonal: Lower-left to upper-right
                float distToBaroque = abs(rotatedCoord.y - rotatedCoord.x);
                if (distToBaroque < diagonalWidth)
                    return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
            }
            
            if (actualSubType == 0 || actualSubType == 2) {
                // Sinister diagonal: Upper-left to lower-right
                float distToSinister = abs(rotatedCoord.y - (1.0 - rotatedCoord.x));
                if (distToSinister < diagonalWidth)
                    return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
            }
        }        // Phi Grid (Golden Grid)
        else if (actualGuideType == 5) { // GUIDE_PHI_GRID / 100
            // Phi proportions (golden ratio)
            float phi = 1.0 / 1.618;
            
            // Vertical lines at phi and 1-phi
            if (abs(frameCoord.x - phi) < gridWidthX || abs(frameCoord.x - (1.0 - phi)) < gridWidthX)
                return lerp(originalColor, guideColor, GuideColor.a);
            
            // Horizontal lines at phi and 1-phi
            if (abs(frameCoord.y - phi) < gridWidthY || abs(frameCoord.y - (1.0 - phi)) < gridWidthY)
                return lerp(originalColor, guideColor, GuideColor.a);
        }        // Triangle Composition
        else if (actualGuideType == 6) { // GUIDE_TRIANGLE / 100
            float triHeight = 0.866; // Height of an equilateral triangle
            
            if (actualSubType == 0) { // Centered triangle pointing up
                // Triangle base at bottom
                if (abs(frameCoord.y - 1.0) < gridWidthY && frameCoord.x >= 0.25 && frameCoord.x <= 0.75)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Left side
                float leftSide = 0.5 - 2.0 * (0.5 - frameCoord.y);
                if (abs(frameCoord.x - leftSide) < gridWidthX && frameCoord.y <= 1.0 && frameCoord.y >= 0.0)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Right side
                float rightSide = 0.5 + 2.0 * (0.5 - frameCoord.y);
                if (abs(frameCoord.x - rightSide) < gridWidthX && frameCoord.y <= 1.0 && frameCoord.y >= 0.0)
                    return lerp(originalColor, guideColor, GuideColor.a);
            }
            else if (actualSubType == 1) { // Centered triangle pointing down
                // Triangle base at top
                if (abs(frameCoord.y) < gridWidthY && frameCoord.x >= 0.25 && frameCoord.x <= 0.75)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Left side
                float leftSide = 0.5 - 2.0 * frameCoord.y;
                if (abs(frameCoord.x - leftSide) < gridWidthX && frameCoord.y <= 0.5 && frameCoord.y >= 0.0)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Right side
                float rightSide = 0.5 + 2.0 * frameCoord.y;
                if (abs(frameCoord.x - rightSide) < gridWidthX && frameCoord.y <= 0.5 && frameCoord.y >= 0.0)
                    return lerp(originalColor, guideColor, GuideColor.a);
            }
            else if (actualSubType == 2) { // Rule of triangles - diagonal from lower-left
                float dist = abs(frameCoord.x + frameCoord.y - 1.0);
                if (dist < gridWidthX)
                    return lerp(originalColor, guideColor, GuideColor.a);
            }
        }        // Golden Spiral
        else if (actualGuideType == 7) { // GUIDE_GOLDEN_SPIRAL / 100
            float2 spiralCenter;
            float angle, radius, phi = 1.618;
              // Change spiral orientation based on subtype
            if (actualSubType == 0) { // Lower-right spiral
                spiralCenter = float2(1.0, 1.0);
                angle = atan2(1.0 - frameCoord.y, 1.0 - frameCoord.x);
            }            else if (actualSubType == 1) { // Upper-right spiral
                spiralCenter = float2(1.0, 0.0);
                angle = atan2(frameCoord.y, 1.0 - frameCoord.x);
            }
            else if (actualSubType == 2) { // Upper-left spiral
                spiralCenter = float2(0.0, 0.0);
                angle = atan2(frameCoord.y, frameCoord.x);
            }
            else { // Lower-left spiral
                spiralCenter = float2(0.0, 1.0);
                angle = atan2(1.0 - frameCoord.y, frameCoord.x);
            }
            
            // Normalize angle to [0, 2π)
            if (angle < 0) angle += 2.0 * 3.14159265;
            
            // Calculate distance to spiral center
            float2 delta = abs(frameCoord - spiralCenter);
            float dist = length(delta);
            
            // Calculate the ideal radius for a golden spiral at this angle
            // r = a * e^(b * θ) where b = ln(phi) / (π/2)
            float b = log(phi) / (3.14159265 * 0.5);
            float idealRadius = 0.25 * exp(b * angle);
            
            // Check if we're on the spiral
            if (abs(dist - idealRadius) < 0.02)
                return lerp(originalColor, guideColor, GuideColor.a);
            
            // Draw the golden rectangles
            float phiInv = 1.0 / phi;
              if (actualSubType == 0) { // Lower-right
                if (abs(frameCoord.x - (1.0 - phiInv)) < gridWidthX || abs(frameCoord.y - (1.0 - phiInv)) < gridWidthY)
                    return lerp(originalColor, guideColor, GuideColor.a * 0.7);
            }
            else if (actualSubType == 1) { // Upper-right
                if (abs(frameCoord.x - (1.0 - phiInv)) < gridWidthX || abs(frameCoord.y - phiInv) < gridWidthY)
                    return lerp(originalColor, guideColor, GuideColor.a * 0.7);
            }
            else if (actualSubType == 2) { // Upper-left
                if (abs(frameCoord.x - phiInv) < gridWidthX || abs(frameCoord.y - phiInv) < gridWidthY)
                    return lerp(originalColor, guideColor, GuideColor.a * 0.7);
            }
            else { // Lower-left
                if (abs(frameCoord.x - phiInv) < gridWidthX || abs(frameCoord.y - (1.0 - phiInv)) < gridWidthY)
                    return lerp(originalColor, guideColor, GuideColor.a * 0.7);
            }
        }        // Harmonic Armature / Dynamic Symmetry
        else if (actualGuideType == 8) { // GUIDE_HARMONIC_ARMATURE / 100
            float diagonalWidth = sqrt(gridWidthX * gridWidthX + gridWidthY * gridWidthY);
            
            // Main diagonals
            float distToD1 = abs(frameCoord.x - frameCoord.y);
            float distToD2 = abs(frameCoord.x - (1.0 - frameCoord.y));
            
            if (distToD1 < diagonalWidth || distToD2 < diagonalWidth)
                return lerp(originalColor, guideColor, GuideColor.a);
            
            // Reciprocal
            if (actualSubType > 0) {
                // Vertical and horizontal center lines
                if (abs(frameCoord.x - 0.5) < gridWidthX * 0.7 || abs(frameCoord.y - 0.5) < gridWidthY * 0.7)
                    return lerp(originalColor, guideColor, GuideColor.a * 0.7);
                
                // Additional diagonals for more complex armature
                if (actualSubType > 1) {
                    // Reciprocal diagonals from the center
                    float centerDistY1 = abs((frameCoord.x - 0.5) * 2.0 - (frameCoord.y - 0.5));
                    float centerDistY2 = abs((frameCoord.x - 0.5) * 2.0 + (frameCoord.y - 0.5));
                    
                    if (centerDistY1 < diagonalWidth * 0.7 || centerDistY2 < diagonalWidth * 0.7)
                        return lerp(originalColor, guideColor, GuideColor.a * 0.6);
                }
            }
        }        // Grid
        else if (actualGuideType == 9) { // GUIDE_GRID / 100
            // Determine grid size based on SubType
            int gridSize = 3; // Default to 3x3
            if (actualSubType == 1) gridSize = 4; // 4x4
            else if (actualSubType == 2) gridSize = 5; // 5x5
            else if (actualSubType == 3) gridSize = 6; // 6x6
            
            // Check if we're on a grid line
            for (int i = 1; i < gridSize; i++) {
                float pos = float(i) / float(gridSize);
                
                // Vertical lines
                if (abs(frameCoord.x - pos) < gridWidthX)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Horizontal lines
                if (abs(frameCoord.y - pos) < gridWidthY)
                    return lerp(originalColor, guideColor, GuideColor.a);
            }
        }        // Safe Zones
        else if (actualGuideType == 10) { // GUIDE_SAFE_ZONES / 100
            // Action Safe (90%)
            float actionSafe = 0.05;
            
            // Title Safe (80%)
            float titleSafe = 0.1;
            
            // Draw Action Safe zone
            if ((abs(frameCoord.x - actionSafe) < gridWidthX || abs(frameCoord.x - (1.0 - actionSafe)) < gridWidthX ||
                 abs(frameCoord.y - actionSafe) < gridWidthY || abs(frameCoord.y - (1.0 - actionSafe)) < gridWidthY))
                return lerp(originalColor, guideColor, GuideColor.a);
            
            // Draw Title Safe zone
            if ((abs(frameCoord.x - titleSafe) < gridWidthX || abs(frameCoord.x - (1.0 - titleSafe)) < gridWidthX ||
                 abs(frameCoord.y - titleSafe) < gridWidthY || abs(frameCoord.y - (1.0 - titleSafe)) < gridWidthY)) {
                return lerp(originalColor, float3(1.0, 1.0, 0.5), GuideColor.a * 0.8); // Use a different color
            }
        }
    } // Added missing closing brace for if (actualGuideType != 0 && isInFrame)
      
    // Draw border around active area
    if (GridWidth > 0.0 && isInFrame) {
        float2 pixelSize = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
        // Use consistent physical width for borders
        float borderWidthUniform = pixelSize.y * GridWidth;
        float borderWidthX = borderWidthUniform;
        float borderWidthY = borderWidthUniform;
        
        if (aspectRatio > ReShade::AspectRatio) {
            // Wider aspect ratio - draw horizontal borders
            float topEdge = borderSize.y + VerticalOffset;
            float bottomEdge = 1.0 - borderSize.y + VerticalOffset;
              
            // Draw the horizontal borders exactly at the crop edges
            if ((abs(texcoord.y - topEdge) < borderWidthY) || 
                (abs(texcoord.y - bottomEdge) < borderWidthY))
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
        }
        else {
            // Taller aspect ratio - draw vertical borders
            float leftEdge = borderSize.x + HorizontalOffset;
            float rightEdge = 1.0 - borderSize.x + HorizontalOffset;
            
            // Draw the vertical borders exactly at the crop edges
            if ((abs(texcoord.x - leftEdge) < borderWidthX) || 
                (abs(texcoord.x - rightEdge) < borderWidthX)) { // Added missing parenthesis
                return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
            }
        }
    } // Added missing closing brace for if (GridWidth > 0.0 && isInFrame)
    
    return originalColor;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float3 PS_AspectRatio(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float aspectRatio = GetAspectRatio();
    
    // Determine if the current pixel is inside the aspect ratio frame
    bool isInFrame = true;
    float2 borderSize = float2(0.0, 0.0);
    
    // Calculate border size based on whether the aspect ratio is wider or taller than the screen
    if (aspectRatio > ReShade::AspectRatio) {
        // Wider aspect ratio than screen - black bars on top and bottom
        borderSize.y = (1.0 - (ReShade::AspectRatio / aspectRatio)) / 2.0;
        float topEdge = borderSize.y + VerticalOffset;
        float bottomEdge = 1.0 - borderSize.y + VerticalOffset;
        isInFrame = (texcoord.y >= topEdge) && (texcoord.y <= bottomEdge);
    }
    else {
        // Taller or equal aspect ratio - black bars on sides
        borderSize.x = (1.0 - (aspectRatio / ReShade::AspectRatio)) / 2.0;
        float leftEdge = borderSize.x + HorizontalOffset;
        float rightEdge = 1.0 - borderSize.x + HorizontalOffset;
        isInFrame = (texcoord.x >= leftEdge) && (texcoord.x <= rightEdge);
    }    // Save the original color before applying effects
    float3 originalColor = color;
    
    // Draw composition guides (only inside frame)
    if (isInFrame || GetGuideType(GetGuideValue()) == 0) {
        color = DrawGuides(texcoord, color, GuideColor.rgb, aspectRatio);
    }
    
    // Apply the clipped area color if outside the frame (must be done after guides)
    if (!isInFrame) {
        color = lerp(originalColor, ClippedAreaColor.rgb, ClippedAreaColor.a);
    }
    
    return color;
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_AspectRatio <
    ui_label = "AS GFX: Aspect Ratio";
    ui_tooltip = "Aspect ratio framing tool for precise subject positioning";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_AspectRatio;
    }
}

#endif // __AS_GFX_AspectRatio_1_fx
