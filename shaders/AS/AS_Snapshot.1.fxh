/**
 * AS_Snapshot.1.fxh - Shared backbuffer-snapshot resources
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International (CC BY 4.0)
 *
 * Declares the persistent texture written by AS_VFX_Snapshot and read by
 * AS_VFX_SnapshotFrame (or any other shader that wants a copy of an earlier
 * frame's backbuffer). Both shaders #include this header so they bind the
 * same physical render target.
 *
 * The texture persists across frames; it is only overwritten when the
 * Snapshot shader runs and decides to capture (Current mode every frame,
 * Shutter mode only on shutter-press frames).
 */

#ifndef __AS_Snapshot_1_fxh
#define __AS_Snapshot_1_fxh

texture AS_StageFX_SnapshotTex {
    Width  = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};

sampler AS_StageFX_SnapshotSampler {
    Texture   = AS_StageFX_SnapshotTex;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

#endif // __AS_Snapshot_1_fxh
