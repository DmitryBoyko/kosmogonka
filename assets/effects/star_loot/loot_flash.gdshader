// REEBOO Loot & Pickup VFX - script-animated sprite: flash, flare, ring, glyph or ray burst.
// The effect scripts animate the node scale and `alpha`; `billboard` off draws it flat on the mesh (ground rings).
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

#include "loot_common.gdshaderinc"

uniform int shape : hint_enum("Soft Glow", "Flare", "Ring", "Glyph", "Ray Burst") = 0;
uniform int glyph : hint_range(0, 7) = 0;
uniform bool billboard = true;
uniform vec4 color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float energy : hint_range(0.0, 20.0) = 3.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
// Ring: half width of the band (0..1 of the quad radius).
uniform float ring_width : hint_range(0.005, 0.5) = 0.06;
uniform float ray_count = 12.0;
uniform float spin = 0.0;

void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = loot_billboard(MODEL_MATRIX, INV_VIEW_MATRIX, VIEW_MATRIX, TIME * spin);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float r = length(p);
	float m;
	float hot = 0.0;
	if (shape == 1) {
		vec2 a = abs(p);
		float rays = max(exp(-a.x * 22.0) * (1.0 - a.y), exp(-a.y * 22.0) * (1.0 - a.x));
		vec2 d = abs(vec2(p.x + p.y, p.x - p.y)) * 0.7071;
		float diag = max(exp(-d.x * 30.0) * (1.0 - d.y * 1.6), exp(-d.y * 30.0) * (1.0 - d.x * 1.6)) * 0.5;
		float core = exp(-r * r * 14.0);
		float halo = exp(-r * r * 3.5) * 0.35;
		m = clamp(core * 1.3 + rays + max(diag, 0.0) + halo, 0.0, 1.0);
		hot = core;
	} else if (shape == 2) {
		float band = loot_band(r, 1.0 - ring_width * 1.2, ring_width);
		float inner = smoothstep(1.0 - ring_width * 6.0, 1.0 - ring_width, r) * step(r, 1.0) * 0.25;
		m = clamp(band + inner, 0.0, 1.0);
		hot = band * 0.5;
	} else if (shape == 3) {
		float d = loot_glyph(glyph, p * 1.1);
		float aa = max(fwidth(d), 0.001) * 1.5;
		float solid = 1.0 - smoothstep(-aa, aa, d);
		float glow = exp(-max(d, 0.0) * 7.0) * 0.5;
		m = clamp(solid + glow, 0.0, 1.0);
		hot = solid * smoothstep(-0.04, -0.3, d) * 0.6;
	} else if (shape == 4) {
		float ang = atan(p.y, p.x) / TAU + 0.5;
		float n = loot_pnoise(vec2(ang * ray_count + TIME * spin, 0.5), ray_count);
		float rays = smoothstep(0.35, 0.9, n) * (1.0 - smoothstep(0.15, 1.0, r));
		float core = exp(-r * r * 10.0);
		m = clamp(rays + core, 0.0, 1.0);
		hot = core;
	} else {
		m = exp(-r * r * 4.5) * (1.0 - smoothstep(0.85, 1.0, r));
		hot = exp(-r * r * 16.0) * 0.6;
	}
	vec3 col = mix(color.rgb, core_color.rgb, clamp(hot, 0.0, 1.0));
	ALBEDO = col * energy;
	ALPHA = clamp(m * alpha, 0.0, 1.0);
}
