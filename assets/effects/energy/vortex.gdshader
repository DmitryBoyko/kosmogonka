shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D noise_map : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color;
uniform vec3 hot : source_color = vec3(.82,.97,1.);
uniform float energy_time;
uniform float burst = -1.;
uniform float axis = 1.;
uniform bool orbit = false;

float ring(float x, float radius, float width) {
	return 1.-smoothstep(width,width+max(fwidth(x),.003),abs(x-radius));
}

void fragment() {
	vec2 p = UV*2.-1.;
	float r = length(p);
	float a = atan(p.y,p.x);
	float lr = log(max(r,.035));
	float spiral = a*.3183 + lr*1.26*axis;
	float cloud = texture(noise_map,vec2(spiral-energy_time*.17,lr*.55+energy_time*.34)).r;
	float filaments = texture(noise_map,vec2(spiral*2.+energy_time*.13,lr*1.3-energy_time*.41)).r;
	float dust = smoothstep(.40,.77,cloud*.71+filaments*.46);
	float band = smoothstep(orbit ? .23 : .09,.43,r)*(1.-smoothstep(.73,1.,r));
	float front = smoothstep(.03,.24,r)*(1.-smoothstep(.63,.85,r));
	float rim = ring(r,.69,.015)*(.50+.50*sin(a*5.+energy_time*2.1));
	float outer = ring(r,.84,.008)*smoothstep(.27,.52,fract(a*2.546-energy_time*.12));
	float hot_edge = exp(-abs(r-.70)*10.)*.29;
	float alpha = band*(.13+dust*.55)+rim*.61+outer*.31+hot_edge;
	if (!orbit) alpha += front*(.12+dust*.24);
	if (burst>=0.) {
		float wave = .14+burst*.79;
		alpha = (ring(r,wave,.025+burst*.035) + exp(-abs(r-wave)*12.)*.52)
			*(1.-burst)*(.48+filaments*.48);
	}
	ALBEDO = mix(tint,hot,clamp(rim*.85+dust*.49,0.,1.))*1.13;
	ALPHA = clamp(alpha*(1.-smoothstep(.93,1.,r)),0.,.83);
}
