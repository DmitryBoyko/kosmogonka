shader_type spatial;

uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 base_color : source_color;
uniform vec3 accent : source_color;
uniform float glow = 0.;
uniform bool natural = false;
varying vec3 point;
varying vec3 axis;

void vertex() {
	point = VERTEX;
	axis = NORMAL;
}

void fragment() {
	vec3 p = point * (natural ? .57 : .74);
	vec2 uv = natural ? p.xz + p.y*vec2(.38,.66) : vec2(p.x+p.z,p.y+(p.x-p.z)*.37);
	vec3 paint = texture(surface_map,uv).rgb;
	float grain = dot(paint,vec3(.22,.65,.13));
	float broad = sin(point.y*1.35 + sin(point.x*.68 + point.z*.49)*1.3);
	vec3 ink = mix(base_color,accent,natural ? .24+.18*broad : .14);
	ALBEDO = ink*(.74 + .58*grain + .10*broad + .08*abs(normalize(axis).y));
	ROUGHNESS = natural ? .89 : .70;
	SPECULAR = .18;
	EMISSION = base_color*glow*(.78+.22*grain);
}
