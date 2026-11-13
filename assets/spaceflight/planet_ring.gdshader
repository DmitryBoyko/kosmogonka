shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.82, 0.73, 0.59);
uniform float inner_radius = 0.68;
uniform float outer_radius = 1.0;
uniform float opacity = 0.72;
varying vec2 ring_position;

void vertex() {
	ring_position = VERTEX.xz;
}

void fragment() {
	float radius = length(ring_position);
	float band = (radius - inner_radius) / (outer_radius - inner_radius);
	float antialias = max(fwidth(band), 0.012);
	float edge = smoothstep(0.0, 0.10 + antialias, band) *
		(1.0 - smoothstep(0.87 - antialias, 1.0, band));
	float gap = smoothstep(0.012, 0.06 + antialias, abs(band - 0.67));
	float stripes = 0.70 + 0.16 * sin(band * 53.0) + 0.09 * cos(band * 105.0);
	float light = 0.74 + 0.26 * dot(normalize(ring_position + vec2(0.001)), vec2(-0.8, 0.6));
	ALBEDO = mix(tint * 0.52, tint * 1.15, stripes) * light;
	ALPHA = edge * mix(0.18, 1.0, gap) * stripes * opacity;
}
