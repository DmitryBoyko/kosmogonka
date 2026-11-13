shader_type canvas_item;

uniform vec2 screen_size = vec2(540.0, 1188.0);
uniform sampler2D space : source_color, filter_linear;

void fragment() {
	vec2 source_size = vec2(textureSize(TEXTURE, 0));
	float contain = min(screen_size.x / source_size.x, screen_size.y / source_size.y);
	vec2 pixel = (UV - vec2(0.5)) * screen_size;
	vec2 space_size = vec2(textureSize(space, 0));
	float cover = max(screen_size.x / space_size.x, screen_size.y / space_size.y);
	vec2 back_uv = vec2(0.5) + pixel / (space_size * cover);
	vec3 background = mix(vec3(0.02, 0.035, 0.105), texture(space, back_uv).rgb, 0.6);
	vec2 front_uv = vec2(0.5) + pixel / (source_size * contain);
	vec2 edge = min(front_uv, vec2(1.0) - front_uv);
	float art_alpha = smoothstep(0.0, 0.035, min(edge.x, edge.y));
	vec3 artwork = texture(TEXTURE, clamp(front_uv, vec2(0.0), vec2(1.0))).rgb;
	COLOR = vec4(mix(background, artwork, art_alpha), 1.0);
}
