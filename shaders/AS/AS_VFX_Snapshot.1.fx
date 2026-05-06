/**
 * AS_VFX_Snapshot.1.fx - Snapshot Capture
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International (CC BY 4.0)
 *
 * Captures the current backbuffer to a persistent texture readable by
 * AS_VFX_SnapshotFrame and any other shader that #includes AS_Snapshot.1.fxh.
 *
 * Two capture modes:
 *   - Current : the snapshot mirrors the live backbuffer every frame.
 *   - Shutter : the snapshot is overwritten only on the frame the bound
 *               shutter key is pressed; otherwise the prior capture is held.
 *
 * Place this technique earlier in ReShade's effect order than any consumer
 * (AS_VFX_SnapshotFrame). Otherwise — in Current mode — the consumer's own
 * composited output gets folded back into the next frame's snapshot, creating
 * a feedback loop.
 */

#ifndef __AS_VFX_Snapshot_1_fx
#define __AS_VFX_Snapshot_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Snapshot.1.fxh"

namespace AS_Snapshot {

static const int MODE_CURRENT = 0;
static const int MODE_SHUTTER = 1;

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int Mode <
    ui_type = "combo";
    ui_label = "Capture Mode";
    ui_tooltip = "Current: every frame the snapshot mirrors the live backbuffer.\n"
                 "Shutter: capture only when the shutter key is pressed; otherwise the prior frame is held.";
    ui_items = "Current\0Shutter\0";
    ui_category = "Capture";
> = MODE_CURRENT;

uniform float ShutterKey <
    source = "key";
    keycode = 0x70;
    mode = "press";
    ui_label = "Shutter Key";
    ui_tooltip = "Press to capture in Shutter mode. Default F1 (rebind in ReShade's keybind UI).";
    ui_category = "Capture";
>;

float4 PS_Snapshot(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    bool capture = (Mode == MODE_CURRENT) || (Mode == MODE_SHUTTER && ShutterKey > 0.5);
    if (!capture) discard;
    return tex2D(ReShade::BackBuffer, texcoord);
}

} // namespace AS_Snapshot

technique AS_VFX_Snapshot <
    ui_label   = "[AS] VFX: Snapshot";
    ui_tooltip = "Captures the current backbuffer to a persistent texture readable by AS_VFX_SnapshotFrame. "
                 "Place earlier in the technique list than any consumer shader to avoid feedback in Current mode.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader  = AS_Snapshot::PS_Snapshot;
        RenderTarget = AS_StageFX_SnapshotTex;
    }
}

#endif // __AS_VFX_Snapshot_1_fx
