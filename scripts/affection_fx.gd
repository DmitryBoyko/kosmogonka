extends Node3D
## Bounded neon hearts: visual feedback only, never a pickup or collision.
var pool: Array[MeshInstance3D]=[]
var live: Array[Dictionary]=[]
var serial:=0
var reduced_motion:=false

func build() -> void:
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for i in 65:
		var a:=TAU*i/64.0
		points.append(Vector3(16*pow(sin(a),3),13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a),0)/17.0)
	for i in 64:
		var a:=points[i]; var b:=points[i+1]
		for v in [a*0.76,b,b*0.76,a*0.76,a,b]: st.add_vertex(v)
	var mesh:=st.commit()
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.albedo_color=Color("ff71d2")
	mat.emission_enabled=true; mat.emission=Color("ff3ba7"); mat.emission_energy_multiplier=1.8
	for i in 12:
		var n:=MeshInstance3D.new(); add_child(n)
		n.mesh=mesh; n.material_override=mat.duplicate(); n.visible=false
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pool.append(n)

func emit_hearts(source: Vector3, camera: Camera3D, big: bool=false) -> void:
	for i in (2 if reduced_motion else 5 if big else 3):
		var node:=pool[serial%pool.size()]; serial+=1
		for old in live.duplicate():
			if old.node==node: live.erase(old)
		var side: float=(i-1 if not big else i-2)*0.13
		var target: Vector3=camera.global_position-camera.global_basis.z*1.0+camera.global_basis.x*side+camera.global_basis.y*0.12
		live.append({"node":node,"from":source,"to":target,"age":0.0,"duration":0.9+i*0.07,"side":side})
		node.global_position=source; node.visible=true

func advance(dt: float, camera: Camera3D, active: bool) -> void:
	if not active: clear(); return
	for item in live.duplicate():
		item.age+=dt
		var t: float=item.age/item.duration
		if t>=1: item.node.visible=false; live.erase(item); continue
		var n: MeshInstance3D=item.node
		if reduced_motion:
			n.global_position=item.from+Vector3(item.side,0.12,0)
		else:
			n.global_position=item.from.lerp(item.to,t*t)+camera.global_basis.x*sin(t*PI)*item.side+Vector3.UP*sin(t*PI)*0.18
		n.look_at(camera.global_position,Vector3.UP)
		n.scale=Vector3.ONE*(0.10 if reduced_motion else lerpf(0.07,0.11,t))
		n.material_override.albedo_color.a=smoothstep(0,0.08,t)*(1-smoothstep(0.6,1,t))*0.9

func clear() -> void:
	for item in live: item.node.visible=false
	live.clear()
