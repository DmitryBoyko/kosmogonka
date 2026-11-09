extends Node
## Opt-in QA only: swept eye / near-plane rays against rendered solid triangles.
## Keep disabled during FPS benchmarks; this intentionally inspects CPU geometry.
var app:Node
var report:Dictionary={"samples":0,"triangles":0,"exact_tests":0,"collisions":[],"features":{}}
var faces:Dictionary={}
var previous:Dictionary={}
var delay:=0.
func _process(dt:float) -> void:
	if app.state!="run" or not app.get_tree().root.get_node("Profile").first_person:return
	delay-=dt
	if delay>0.:return
	delay=.08;report.samples+=1
	for event:Dictionary in app.events:
		if not is_instance_valid(event.node) or event.done or absf(app.distance-event.s)>event.length*.5+6.:continue
		inspect(event.node,event.kind)
	if not app.loop_routes.active.is_empty():inspect(app.loop_routes.active.node,"loop_"+app.loop_routes.active.kind)
func inspect(source:Node3D,kind:String) -> void:
	report.features[kind]=int(report.features.get(kind,0))+1
	var eye:Vector3=app.camera.global_position
	var end_points:Array[Vector3]=[]
	var half_height:float=tan(deg_to_rad(app.camera.fov)*.5)*app.camera.near
	var half_width:float=half_height*app.get_viewport().size.x/float(app.get_viewport().size.y)
	for side in [-1.,1.]:
		for up in [-1.,1.]:end_points.append(app.camera.to_global(Vector3(side*half_width,up*half_height,-app.camera.near)))
	for node:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		if not node.is_visible_in_tree() or node.mesh==null:continue
		if node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and not (kind.begins_with("loop_") and node.get_parent()==source):continue
		var inv:=node.global_transform.affine_inverse();var at:Vector3=inv*eye;var id:int=node.get_instance_id()
		var before:Vector3=previous.get(id,at);previous[id]=at
		var bounds:AABB=node.mesh.get_aabb().grow(.10)
		if not bounds.has_point(at) and bounds.intersects_segment(before,at)==null:continue
		var mesh_id:int=node.mesh.get_instance_id()
		if not faces.has(mesh_id):
			var vertices:PackedVector3Array=node.mesh.get_faces();var boxes:Array[AABB]=[]
			for f in range(0,vertices.size(),3):boxes.append(AABB(vertices[f],Vector3.ZERO).expand(vertices[f+1]).expand(vertices[f+2]).grow(.1))
			faces[mesh_id]={"vertices":vertices,"boxes":boxes}
		var triangles:PackedVector3Array=faces[mesh_id].vertices;var hit:=false
		for i in range(0,triangles.size(),3):
			report.triangles+=1
			var face_bounds:AABB=faces[mesh_id].boxes[i/3]
			if not face_bounds.has_point(at) and face_bounds.intersects_segment(before,at)==null:continue
			report.exact_tests+=1
			if before.distance_squared_to(at)>.00001 and Geometry3D.segment_intersects_triangle(before,at,triangles[i],triangles[i+1],triangles[i+2])!=null:hit=true;break
			for end:Vector3 in end_points:
				if Geometry3D.segment_intersects_triangle(at,inv*end,triangles[i],triangles[i+1],triangles[i+2])!=null:hit=true;break
			if hit:break
		if hit and report.collisions.size()<32:
			report.collisions.append({"world":app.planet,"distance":app.distance,"kind":kind,"mesh":str(node.get_path()),"eye":[eye.x,eye.y,eye.z]})
