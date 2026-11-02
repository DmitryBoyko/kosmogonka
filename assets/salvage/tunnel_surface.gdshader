shader_type spatial;
render_mode specular_schlick_ggx, cull_disabled;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tile_scale = .65;
uniform float metalness = .65;
uniform float roughness = .6;
uniform int finish_pattern = -1;
uniform vec4 accent : source_color = vec4(.25,.8,.8,1);
varying vec3 local_point;
varying vec3 local_normal;
varying vec3 view_point;
void vertex() {
	local_point = VERTEX;
	local_normal = NORMAL;
	view_point = (MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec3 w = pow(abs(normalize(local_normal)),vec3(5.0));
	w /= max(w.x+w.y+w.z,.001);
	vec3 p = local_point*tile_scale;
	vec3 sample_color = texture(surface_map,p.yz).rgb*w.x + texture(surface_map,p.xz).rgb*w.y + texture(surface_map,p.xy).rgb*w.z;
	float height = dot(sample_color,vec3(.299,.587,.114));
	vec3 dx = dFdx(view_point), dy = dFdy(view_point);
	vec3 rx = cross(dy,NORMAL), ry = cross(NORMAL,dx);
	float det = dot(dx,rx);
	vec3 bump = sign(det)*(dFdx(height)*rx+dFdy(height)*ry);
	NORMAL = normalize(abs(det)*NORMAL-bump*.0015);
	vec3 base=sample_color*tint;
 float mask=0.0;
 vec2 uv=local_point.xy*w.z+local_point.zy*w.x+local_point.xz*w.y;
 if (finish_pattern==0) mask=step(.78,fract(uv.x*3.5)); // fluted alloy
 else if (finish_pattern==1) mask=step(.72,fract((uv.x+uv.y)*2.0)); // rescue chevrons
 else if (finish_pattern==2) mask=step(.93,fract(uv.x*5.0))+step(.93,fract(uv.y*5.0)); // ceramic quilt
 else if (finish_pattern==3) mask=smoothstep(.45,.5,abs(sin(uv.x*9.0)*sin(uv.y*9.0))); // diamond weave
 else if (finish_pattern==4) mask=step(.86,fract(uv.y*4.5)); // cold storage rings
 else if (finish_pattern==5) mask=step(.84,fract(uv.x*2.0+sin(uv.y*4.0)*.22)); // flowing bio ribs
 else if (finish_pattern==6) mask=step(.82,fract(uv.x*6.0))*step(.4,fract(uv.y*3.0)); // stepped data etch
 else if (finish_pattern==7) mask=step(.85,fract((uv.x-uv.y)*4.0))*step(.85,fract((uv.x+uv.y)*4.0)); // riveted foil
 else if (finish_pattern==8) mask=smoothstep(.65,.95,sin(uv.x*17.0+sin(uv.y*7.0))); // brushed copper
 else if (finish_pattern==9) mask=step(.88,fract(uv.x*3.0+floor(uv.y*3.0)*.5)); // staggered armour
 ALBEDO=mix(base,accent.rgb*mix(.65,1.0,height),clamp(mask,0.0,1.0)*.45);
	METALLIC = metalness;
	ROUGHNESS = clamp(roughness+(1.0-height)*.15,.2,.98);
	SPECULAR = .4;
}
