extends Node3D
var material:ShaderMaterial
var walls:Array[Dictionary]=[]
func build(planet:int) -> void:
	name="FinishForceField"
	for definition in [[Vector3(0,3.,39.),122.,0.],[Vector3(0,3.,-87.),122.,PI],[Vector3(-61.,3.,-24.),126.,PI*.5],[Vector3(61.,3.,-24.),126.,-PI*.5]]:
		var frame:=Node3D.new(); add_child(frame); frame.position=definition[0]; frame.rotation.y=definition[2]
		var mesh:=QuadMesh.new(); mesh.size=Vector2(definition[1],6.)
		var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/finish_field.gdshader")
		mat.set_shader_parameter("tint",Color(preload("res://scripts/planets.gd").get_data(planet).accent).lightened(.2))
		if material==null: material=mat
		var surface:=MeshInstance3D.new(); frame.add_child(surface); surface.mesh=mesh; surface.material_override=mat; surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var body:=StaticBody3D.new(); frame.add_child(body); body.collision_layer=2; body.collision_mask=0
		var collider:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(definition[1],6.,.16); collider.shape=shape; body.add_child(collider)
		walls.append({"node":frame,"material":mat,"width":float(definition[1])})
func advance(clock:float,at:Vector3,reduced:bool) -> void:
	for wall:Dictionary in walls:
		var local_at:Vector3=wall.node.transform.affine_inverse()*at
		var near:float=1.-smoothstep(.5,3.,absf(local_at.z))
		wall.material.set_shader_parameter("proximity",near)
		wall.material.set_shader_parameter("touch_point",Vector2(clampf(local_at.x/wall.width+.5,0,1),clampf((local_at.y+3.9)/6.,0,1)))
		wall.material.set_shader_parameter("flow_time",0. if reduced else clock)
