shader_type canvas_item;
uniform vec4 top_color : source_color = vec4(.65,1.,.96,1.);
uniform vec4 bottom_color : source_color = vec4(.20,.65,1.,1.);

void fragment() {
	vec4 pixel=texture(TEXTURE,UV);
	float shade=texture(TEXTURE,UV-vec2(0.,.045)).a;
	float edge=max(0.,pixel.a-texture(TEXTURE,UV+vec2(0.,.035)).a);
	vec3 tint=mix(top_color.rgb,bottom_color.rgb,smoothstep(.19,.81,UV.y));
	COLOR=vec4(mix(vec3(.08,.12,.30),tint+edge*.25,pixel.a),max(pixel.a,shade*.72));
}
