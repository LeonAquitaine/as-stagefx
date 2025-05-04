## Context
I'm developing HLSL shader effects for the AS StageFX collection, which are used in ReShade for real-time post-processing in games. These shaders focus on high-quality, procedural visual effects with standardized interfaces.

## Rules and Standards

### Texture-Based Effects
When implementing texture-based effects:

1. **Preprocessor-Based Texture UI**: For texture resources that need to appear in the UI, use preprocessor definitions:
   ```hlsl
   #ifndef TEXTURE_PATH
   #define TEXTURE_PATH "default.png" // Default texture path
   #endif

   texture EffectTexture < source = TEXTURE_PATH; ui_label = "Effect Texture"; > 
   { Width = 256; Height = 256; Format = RGBA8; };
   ```

2. **Texture UI Visibility Helpers**: Add UI elements to ensure texture selection is visible:
   ```hlsl
   uniform bool RefreshUI < source = "key"; keycode = 13; mode = "toggle"; 
      ui_label = " "; ui_text = "Press Enter to refresh UI"; 
      ui_category = "Texture Settings"; > = false;
   ```

3. **Proper Sampler Configuration**: Always specify all sampler states explicitly:
   ```hlsl
   sampler TextureSampler { 
      Texture = TextureName; 
      AddressU = REPEAT; // or CLAMP, BORDER, MIRROR
      AddressV = REPEAT;
      MagFilter = LINEAR; // or POINT
      MinFilter = LINEAR; 
      MipFilter = LINEAR; // or POINT, NONE
   };
   ```

### Rotated Distortion Effects
When implementing distortion effects with rotation support:

1. **Separation of Rotation and Sampling**: 
   - Calculate distortion vectors using rotated coordinates 
   - Apply resulting distortion to original (non-rotated) texture coordinates
   ```hlsl
   // Calculate distortion in rotated space
   float2 rotatedUV = ApplyRotationTransform(texcoord, rotation);
   float2 distortionVector = CalculateDistortion(rotatedUV);
   
   // Apply distortion to original texcoord (not rotated texcoord)
   float2 distortedUV = texcoord + distortionVector;
   float4 result = tex2D(ReShade::BackBuffer, distortedUV);
   ```

2. **Aspect Ratio Correction for Distortion Vectors**: When applying distortion calculated in normalized space:
   ```hlsl
   // Calculate distortion in normalized/rotated space
   float2 distortion = CalculateDistortion(normalizedUV);
   
   // Correct the distortion vector for aspect ratio before applying
   distortion.x /= ReShade::AspectRatio;
   
   // Apply the corrected distortion to the original coordinates
   float2 finalUV = texcoord + distortion * intensity;
   ```

3. **Safe Texture Sampling**: Always clamp distorted coordinates to prevent artifacts:
   ```hlsl
   distortedUV = clamp(distortedUV, 0.0, 1.0);
   float4 result = tex2D(ReShade::BackBuffer, distortedUV);
   ```

### Targeted Audio Reactivity

1. **Parameter-Specific Audio Targeting**: Let users select which parameter to affect:
   ```hlsl
   uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter";
      ui_items = "None\0Parameter A\0Parameter B\0"; > = 0;
      
   // In pixel shader
   if (AudioTarget == 1) { // Parameter A
       paramA = baseParamA + (baseParamA * audioValue * scaleFactor);
   } else if (AudioTarget == 2) { // Parameter B
       paramB = saturate(baseParamB + (baseParamB * audioValue * scaleFactor));
   }
   ```

2. **Local Parameter Storage**: Use local variables for audio-modified parameters:
   ```hlsl
   // Define base and modified parameters
   float paramBaseline = ParamUniform;
   float paramFinal = paramBaseline;
   
   // Apply audio reactivity if enabled
   if (AudioTarget == targetIndex) {
       float audioValue = AS_applyAudioReactivity(1.0, Audio_Source, Audio_Multiplier, true) - 1.0;
       paramFinal = paramBaseline + (paramBaseline * audioValue * 0.5);
   }
   
   // Use the final parameter value in calculations
   ```

3. **Uniform Modification Safety**: Never modify uniform values directly, use local variables instead.

### Noise Function Usage

// ...existing code...