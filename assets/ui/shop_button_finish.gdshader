shader_type canvas_item;
uniform sampler2D alloy : source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec2 pixel = UV / max(fwidth(UV),vec2(.00001));
	float grain=dot(texture(alloy,pixel/vec2(96.,57.)).rgb,vec3(.22,.65,.13));
	float edge = min(min(UV.x,1.-UV.x)*10.,min(UV.y,1.-UV.y)*5.);
	COLOR=vec4(.35,.67,.94,(.04+.13*grain)*smoothstep(0.,.65,edge));
}
