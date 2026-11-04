extends Node
var jobs:Array[Dictionary]=[]
var seen:Dictionary={}
var view:SubViewport
var previous:GeometryInstance3D
var sun_lights:Array[DirectionalLight3D]=[]
var spot:SpotLight3D
var world:WorldEnvironment
var outdoor:Environment
var indoor:Environment
func setup(environment:Environment,suns:Array,room_environment:Environment=null) -> void:
	outdoor=environment; indoor=room_environment
	view=SubViewport.new(); view.size=Vector2i(32,32); view.own_world_3d=true; add_child(view)
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	world=WorldEnvironment.new(); world.environment=environment; view.add_child(world)
	var eye:=Camera3D.new(); view.add_child(eye); eye.position=Vector3(0,2,8); eye.look_at(Vector3.ZERO); eye.current=true
	for original:DirectionalLight3D in suns:
		var light:=DirectionalLight3D.new(); light.rotation=original.rotation; light.light_energy=original.light_energy; light.light_color=original.light_color; light.shadow_enabled=original.shadow_enabled; light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL; light.directional_shadow_max_distance=22.; view.add_child(light)
		sun_lights.append(light)
	spot=SpotLight3D.new(); view.add_child(spot); spot.position=Vector3(1.2,4.3,4.); spot.spot_range=13.; spot.spot_angle=58.; spot.look_at(Vector3.ZERO); spot.shadow_enabled=true; spot.hide()
func enqueue(source:Node3D,all_meshes:bool=false,in_room:bool=false) -> void:
	var originals:Array[Node]=source.find_children("*","GeometryInstance3D",true,false)
	if source is GeometryInstance3D: originals.append(source)
	for original:GeometryInstance3D in originals:
		if original is Label3D:
			var key:String="label/"+str(original.billboard)+"/"+str(original.font_size)
			if not seen.has(key):
				seen[key]=true; jobs.append({"label":true,"font":original.font,"text":original.text,"size":original.font_size,"billboard":original.billboard,"room":in_room})
			continue
		var mesh:Mesh=original.mesh if original is MeshInstance3D else original.multimesh.mesh if original is MultiMeshInstance3D else null
		if mesh==null: continue
		var overrides:Array[Material]=[]; var key:String=("room/" if in_room else "outdoor/")+("multi/" if original is MultiMeshInstance3D else "mesh/")
		for surface in mesh.get_surface_count():
			var material:Material=original.get_active_material(surface) if original is MeshInstance3D else original.material_override
			key+=str(material.get_instance_id()) if material else "0"
			if original is MeshInstance3D: overrides.append(original.get_surface_override_material(surface))
		if all_meshes: key+="/"+str(mesh.get_instance_id())
		if seen.has(key): continue
		seen[key]=true
		jobs.append({"mesh":mesh,"multi":original.multimesh if original is MultiMeshInstance3D else null,"material":original.material_override,"overrides":overrides,"room":in_room,"shadow":original.cast_shadow})
func _process(_dt:float) -> void:
	if is_instance_valid(previous): previous.free(); previous=null
	if jobs.is_empty(): return
	var job:Dictionary=jobs.pop_front(); var copy:GeometryInstance3D
	for light in sun_lights: light.visible=not job.room
	spot.visible=job.room; world.environment=indoor if job.room and indoor else outdoor
	if job.has("label"):
		var label:=Label3D.new(); label.font=job.font; label.text=job.text; label.font_size=job.size; label.pixel_size=.008; label.billboard=job.billboard; label.outline_size=5
		view.add_child(label); view.render_target_update_mode=SubViewport.UPDATE_ONCE; previous=label; return
	if job.multi:
		var multi:=MultiMeshInstance3D.new(); multi.multimesh=job.multi; copy=multi
	else:
		var mesh:=MeshInstance3D.new(); mesh.mesh=job.mesh; copy=mesh
		for i in job.overrides.size(): mesh.set_surface_override_material(i,job.overrides[i])
	copy.material_override=job.material; copy.cast_shadow=job.shadow
	view.add_child(copy)
	var bounds:AABB=copy.get_aabb(); var factor:float=2./maxf(.1,bounds.size.length())
	copy.scale=Vector3.ONE*factor; copy.position=-bounds.get_center()*factor
	view.render_target_update_mode=SubViewport.UPDATE_ONCE; previous=copy
