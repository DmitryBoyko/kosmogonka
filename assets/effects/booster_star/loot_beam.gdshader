// REEBOO Loot & Pickup VFX - column of light (an open CylinderMesh): loot beams, light columns, soft domes.
// Brightest where the surface faces the camera, so the column has no hard outline; streaks scroll upward.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

#include "loot_common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform float energy : hint_range(0.0, 20.0) = 2.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
// Higher = thinner, softer core.
uniform float edge_soft : hint_range(0.2, 8.0) = 1.5;
uniform float scroll = 0.6;
uniform float animation_time = 0.0;
// 0 = smooth, 1 = strong noise streaks.
uniform float streaks : hint_range(0.0, 1.0) = 0.6;
uniform float streak_count = 8.0;
uniform float top_fade : hint_range(0.1, 6.0) = 1.2;
// 0..1: how much of the column is drawn, from the ground up (drop animation).
uniform float grow : hint_range(0.0, 1.0) = 1.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.15;
uniform float bottom_fade : hint_range(0.0, 0.5) = 0.04;

void fragment() {
	float h = 1.0 - UV.y;
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float body = pow(facing, edge_soft);
	float n = loot_pnoise(vec2(UV.x * streak_count, h * 3.0 - animation_time * scroll), streak_count);
	float n2 = loot_pnoise(vec2(UV.x * streak_count * 2.0 + 3.1, h * 6.0 - animation_time * scroll * 1.7), streak_count * 2.0);
	float st = mix(1.0, smoothstep(0.2, 0.85, n * 0.65 + n2 * 0.35) * 1.7, streaks);
	float vert = pow(clamp(1.0 - h, 0.0, 1.0), top_fade) * smoothstep(0.0, max(bottom_fade, 0.001), h);
	float cut = 1.0 - smoothstep(grow - 0.12, grow, h);
	float beat = 1.0 - pulse + pulse * (0.5 + 0.5 * sin(animation_time * 3.0 - h * 4.0));
	ALBEDO = color.rgb * energy;
	ALPHA = clamp(body * st * vert * cut * beat * alpha, 0.0, 1.0);
}
