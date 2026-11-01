shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 repeats=vec2(1.0);
uniform bool road=false;
uniform vec4 road_color : source_color=vec4(0.13,0.17,0.26,1.0);
uniform vec4 accent_color : source_color=vec4(0.5,0.9,0.8,1.0);
uniform float relief=0.12;
void fragment() {
	vec2 uv=UV*repeats;
	if (!road) uv=abs(fract(uv*0.5)*2.0-1.0);
	vec3 surface=texture(surface_texture,uv).rgb;
	float h=dot(surface,vec3(0.299,0.587,0.114));
	if (road) {
		ALBEDO=road_color.rgb*mix(0.75,1.45,smoothstep(0.025,0.30,h));
		float u=fract(uv.x);
		float rail=min(abs(u-0.12),abs(u-0.88));
		float light=(1.0-smoothstep(0.0015,0.005,rail))*(0.35+0.65*smoothstep(0.04,0.12,fract(uv.y)));
		EMISSION=accent_color.rgb*light*0.23;
		ROUGHNESS=0.72;
		METALLIC=0.20;
	} else {
		ALBEDO=surface;
		ROUGHNESS=0.94;
	}
	if (relief>0.0) {
		vec2 pixel=1.0/vec2(textureSize(surface_texture,0));
		float hx=dot(texture(surface_texture,uv+vec2(pixel.x,0)).rgb,vec3(0.299,0.587,0.114));
		float hy=dot(texture(surface_texture,uv+vec2(0,pixel.y)).rgb,vec3(0.299,0.587,0.114));
		NORMAL_MAP=normalize(vec3((h-hx)*relief*8.0,(h-hy)*relief*8.0,1.0))*0.5+0.5;
	}
}
