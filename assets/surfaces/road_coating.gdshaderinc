// Calibrate each texture before tinting so the seams and grains survive daylight.
vec3 road_coating(vec3 tint, vec3 detail_tint, vec3 sample_rgb, vec2 uv, vec2 levels, int style, float natural_color, bool srgb) {
	float signal = dot(sample_rgb, vec3(.299, .587, .114));
	vec3 source_hue = clamp(sample_rgb / max(.075,signal),vec3(.74),vec3(1.31));
	if (!srgb) {
		signal = 1.055 * pow(signal, 1.0 / 2.4) - .055;
	}
	float texture_tone = smoothstep(levels.x, levels.y, signal);
	float shade = mix(.66, 1.12, texture_tone);
	if (style == 3) shade = mix(.74, 1.08, texture_tone);
	if (style == 0) {
		// The inset trim picks up the biome hue while the graphite stays matte.
		tint = mix(tint, detail_tint, smoothstep(.32, .46, signal) * .76);
	} else if (style == 1 || style == 4) {
		// Compact the running surface between the softer shoulders.
		float verge = smoothstep(.32, .49, abs(fract(uv.x) - .5));
		shade *= 1.0 - .14 * verge;
	} else if (style == 2) {
		vec2 tile = uv * vec2(1.5, 2.0);
		vec2 aa = fwidth(tile);
		tile.x += mod(floor(tile.y), 2.0) * .5;
		vec2 edge = abs(fract(tile + .5) - .5);
		vec2 joint = (1.0 - smoothstep(vec2(.018), vec2(.032) + aa, edge))
			* (1.0 - smoothstep(vec2(.10), vec2(.70), aa));
		shade *= 1.0 - .30 * max(joint.x, joint.y);
	}
	tint *= mix(vec3(1.),source_hue,natural_color);
	return tint * shade;
}
