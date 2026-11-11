shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(.24, 1., .86);
uniform float animation_time = 0.;
uniform bool airborne = false;

void vertex() {
	if (airborne) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

float stroke(float distance_to_line, float width) {
	return 1. - smoothstep(width, width + max(fwidth(distance_to_line), .003), abs(distance_to_line));
}

void fragment() {
	vec2 point = UV * 2. - 1.;
	float radius = length(point);
	float sector = fract(atan(point.y, point.x) * .95493 + animation_time * .22);
	float segments = smoothstep(.06, .15, sector) * (1. - smoothstep(.74, .83, sector));
	float rim = stroke(radius - .72, .023) * segments;
	float ticks = stroke(radius - .87, .016) * smoothstep(.72, .87, sector);
	float chevron = airborne ? 0. : stroke(point.y - abs(point.x) * .68 + .12, .037)
		* (1. - smoothstep(.34, .42, abs(point.x)));
	float spill = exp(-18. * abs(radius - .72)) * .22;
	ALBEDO = color * 1.55;
	ALPHA = clamp(rim + ticks * .55 + chevron * .77 + spill, 0., .90);
}
