shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tile_scale = .65;
uniform float metalness = .65;
uniform float roughness = .6;
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
	ALBEDO = sample_color*tint;
	METALLIC = metalness;
	ROUGHNESS = clamp(roughness+(1.0-height)*.15,.2,.98);
	SPECULAR = .4;
}
