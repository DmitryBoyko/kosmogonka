shader_type spatial;
render_mode unshaded;
uniform vec4 tint : source_color=vec4(.4,1.0,.85,1.0);
uniform float palette_offset=0.0;
uniform float flow_time=0.0;
uniform float track_distance=0.0;
uniform bool reduced_motion=false;
uniform vec2 track_rotation=vec2(1.,0.);
varying float world_z;
vec3 lamp_color(float index) {
 float i=mod(index+palette_offset,6.0);
 if(i<1.0) return vec3(1.0,.30,.56);
 if(i<2.0) return vec3(1.0,.63,.18);
 if(i<3.0) return vec3(1.0,.90,.28);
 if(i<4.0) return vec3(.30,1.0,.58);
 if(i<5.0) return vec3(.25,.82,1.0);
 return vec3(.76,.43,1.0);
}
void vertex() { world_z=dot((MODEL_MATRIX*vec4(VERTEX,1.0)).xz,track_rotation.yx); }
void fragment() {
 float lamp=1.0-smoothstep(.79,.89,fract((world_z-track_distance)/.75));
 // A crest moves towards negative Z: ahead, away from the running character.
 float phase=fract((world_z+flow_time*22.0)/9.0);
 float crest=smoothstep(.01,.10,phase)*(1.0-smoothstep(.25,.39,phase));
 float power=reduced_motion ? .85 : .65+crest*.55;
 // Each three-lamp group keeps its colour as the track moves; only the crest travels.
 vec3 color=lamp_color(floor((track_distance-world_z)/2.25));
 ALBEDO=mix(vec3(.045,.07,.10),color*power,lamp);
 EMISSION=color*lamp*power*.55;
}
