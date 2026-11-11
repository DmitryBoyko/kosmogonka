shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform bool fire_mode=false;
uniform bool rocket_trail=false;
uniform float flow_time = 0.0;
uniform float power : hint_range(0.0,1.0) = 0.0;
uniform float phase_offset = 0.0;
uniform sampler2D plume_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D trail_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
varying vec2 plume_uv;

float hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() { plume_uv=UV; }
void fragment() {
	float t=clamp(plume_uv.y,0.0,1.0);
	float time=flow_time+phase_offset;
	if (rocket_trail) {
		// REEBOO Stylized Projectiles flame-ribbon breakup, paced by gameplay time.
		float along=t*3.0-time*3.8;
		float n=texture(trail_noise,vec2(along,plume_uv.x*.70)).r;
		float n2=texture(trail_noise,vec2(along*1.9,plume_uv.x*1.3+.37)).r;
		float across=(plume_uv.x-.5)*2.0;
		float d=abs(across+(n-.5)*t*.64);
		float body=1.0-smoothstep(.22,.83,d+t*.36);
		float burn=smoothstep(t*.70-.14,t*.70+.08,n2*(1.0-d*.42));
		float hot=(1.0-smoothstep(.025,.35,d+t*.15))*(1.0-smoothstep(.10,.71,t));
		float shear=texture(plume_texture,vec2(clamp(.5+across*.4,0.,1.),t)).a;
		float sparks=smoothstep(.65,.84,n*n2*1.8)*smoothstep(.25,.75,t)*body;
		vec3 flame=mix(vec3(1.0,.26,.025),vec3(1.0,.92,.36),hot);
		ALBEDO=flame*(1.2+power*.85);
		EMISSION=flame*hot*.8;
		ALPHA=clamp((body*burn*(.58+.42*shear)+sparks*.60)*power*smoothstep(0.0,.025,t)*(1.0-smoothstep(.65,1.0,t)),0.0,.88);
	} else {
	float turbulence=noise(vec2(t*11.0-time*9.0,plume_uv.x*8.0+time*1.5));
	float fine=noise(vec2(t*29.0-time*23.0,plume_uv.x*19.0-time*3.0));
	float eddies=0.64+turbulence*0.22+fine*0.14;
	vec2 warp=vec2((turbulence-0.5)*0.055*t,sin(t*25.0-time*17.0)*0.012*t);
	vec4 gas=texture(plume_texture,clamp(plume_uv+warp,vec2(0.0),vec2(1.0)));
	vec4 alternate=texture(plume_texture,clamp(vec2(1.0-plume_uv.x,t)-warp,vec2(0.0),vec2(1.0)));
	gas=mix(gas,alternate,0.22+sin(time*1.8)*0.12);
	float brightness=max(gas.r,max(gas.g,gas.b));
	float fade=smoothstep(0.0,0.025,t)*(1.0-smoothstep(0.85,1.0,t));
	if(fire_mode) gas.rgb=mix(vec3(1.,.27,.025),vec3(1.,.95,.72),clamp(brightness*brightness*1.5,0.,1.))*brightness;
	else {
		float core=(1.0-smoothstep(.06,.27,abs(plume_uv.x-.5)))*(1.0-smoothstep(.35,.82,t));
		gas.rgb=mix(gas.rgb,vec3(1.,.82,.30)*brightness,core*.42);
	}
	ALBEDO=gas.rgb*power*1.5;
	EMISSION=gas.rgb*power*1.5;
	ALPHA=clamp(gas.a*brightness*fade*eddies*power*0.7,0.0,0.9);
	}
}
