shader_type spatial;
render_mode unshaded;
uniform vec4 tint : source_color=vec4(.4,1.0,.85,1.0);
uniform float flow_time=0.0;
uniform float track_distance=0.0;
uniform bool reduced_motion=false;
varying float world_z;
void vertex() { world_z=(MODEL_MATRIX*vec4(VERTEX,1.0)).z; }
void fragment() {
 float lamp=1.0-smoothstep(.79,.89,fract((world_z-track_distance)/.75));
 // A crest moves towards negative Z: ahead, away from the running character.
 float phase=fract((world_z+flow_time*22.0)/9.0);
 float crest=smoothstep(.01,.10,phase)*(1.0-smoothstep(.25,.39,phase));
 float power=reduced_motion ? .70 : .26+crest*1.25;
 ALBEDO=mix(vec3(.045,.07,.10),tint.rgb*power,lamp);
 EMISSION=tint.rgb*lamp*power*.65;
}
