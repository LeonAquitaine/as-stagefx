# Magic Numbers Conversion

## Summary of Changes

We've identified and addressed numerous magic numbers in the AS StageFX shader collection by
standardizing them as constants in the `AS_Utils.1.fxh` file. This increases code consistency,
improves maintainability, and ensures that common values are used consistently across all shaders.

## New Constants Added to AS_Utils.1.fxh

### Mathematical Constants
- `AS_EPSILON` and `AS_EPSILON_SAFE`: Values for preventing division by zero and precision errors
- Added common fractional constants:
  - `AS_HALF` (0.5)
  - `AS_QUARTER` (0.25)
  - `AS_THIRD` (0.3333)
  - `AS_TWO_THIRDS` (0.6667)

### Common Graphics Constants
- `AS_DEPTH_EPSILON`: Standard value (0.0005) for preventing z-fighting
- `AS_EDGE_AA`: Standard anti-aliasing size for edge transitions (0.05)

### Display and UI Constants
- `AS_RESOLUTION_BASE_HEIGHT` and `AS_RESOLUTION_BASE_WIDTH`: Reference resolution
- `AS_STANDARD_ASPECT_RATIO`: Standard 16:9 ratio
- `AS_UI_POSITION_RANGE`: Standard range for position controls (-1.5 to 1.5)
- `AS_UI_CENTRAL_SQUARE`: Range mapping to central square (-1.0 to 1.0)
- `AS_UI_POSITION_SCALE`: Position scaling factor (0.5)
- Added screen center constants: `AS_SCREEN_CENTER_X` and `AS_SCREEN_CENTER_Y` (0.5)
- Added `AS_RESOLUTION_SCALE` for resolution-independent sizing

### Common UI Value Ranges
- Standardized min/max/default values for common parameters:
  - Zero-One range (0.0 to 1.0)
  - Negative-One to One range (-1.0 to 1.0) 
  - Opacity range (0.0 to 1.0, default 1.0)
  - Blend amount range (0.0 to 1.0, default 1.0)
  - Audio multiplier range (0.0 to 2.0, default 1.0)
  - Scale range (0.1 to 5.0, default 1.0)
  - Speed range (0.0 to 5.0, default 1.0)

### Debug Mode Constants
- `AS_DEBUG_OFF`: Debug mode off (0)
- `AS_DEBUG_MASK`: Debug mask display (1)
- `AS_DEBUG_DEPTH`: Debug depth display (2)
- `AS_DEBUG_AUDIO`: Debug audio display (3)
- `AS_DEBUG_PATTERN`: Debug pattern display (4)

### Animation Constants
- Animation speed multipliers: `AS_ANIMATION_SPEED_SLOW`, `AS_ANIMATION_SPEED_NORMAL`, `AS_ANIMATION_SPEED_FAST`
- Timing constants: `AS_TIME_1_SECOND`, `AS_TIME_HALF_SECOND`, `AS_TIME_QUARTER_SECOND`
- Pattern frequency constants: `AS_PATTERN_FREQ_LOW`, `AS_PATTERN_FREQ_MED`, `AS_PATTERN_FREQ_HIGH`

## Files Modified

1. `AS_Utils.1.fxh`: Added new constant definitions
2. `AS_VFX_WarpDistort.1.fx`: Updated to use constants for:
   - Position scaling and centering 
   - Depth epsilon
3. `AS_VFX_VUMeter.1.fx`: Updated to use depth epsilon constant
4. `AS_VFX_BoomSticker.1.fx`: Updated depth epsilon constant
5. `AS_VFX_DigitalArtifacts.1.fx`: Updated to use AS_HALF constant
6. `AS_VFX_StencilMask.1.fx`: Updated to use AS_HALF and AS_QUARTER 
7. `AS_VFX_ScreenRing.1.fx`: Updated to use AS_HALF
8. `version.txt`: Updated to 1.6.2 to reflect the changes

## Benefits

1. **Consistency**: Same values are used across all shaders, preventing subtle variations
2. **Maintainability**: Changing a value in one place affects all shaders
3. **Readability**: Descriptive constant names make code more understandable
4. **Bug Prevention**: Prevents errors that might occur from manually typing values
5. **Future-Proofing**: Easier to adjust for different displays or platforms
6. **Standards Enforcement**: Helps enforce the coding standards in `AS_CodeStandards.md`

## Recommendations for Future Development

1. Continue to replace remaining magic numbers in shader files
2. Consider creating more specialized constant groups for specific effects or rendering techniques
3. Add explicit `#include` directives to ensure all shaders have access to the constants
4. Update the coding standards document to emphasize using the standardized constants
5. Add constants for common audio multiplier ranges and defaults
6. Standardize debug visualization constants across all effects
