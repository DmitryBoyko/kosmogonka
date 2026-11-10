extends Control
## The portal follows projected actors; it never intercepts taps on their bodies.
var frame:=Rect2()
var selected:=0
var phase:=0.
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func present(camera:Camera3D,kid:Node3D,index:int,canvas_size:Vector2,clock:float,reduced:bool) -> void:
	selected=index;phase=0. if reduced else sin(clock*2.)*.12
	var ratio:Vector2=canvas_size/camera.get_viewport().get_visible_rect().size
	var top:Vector2=camera.unproject_position(kid.global_position+Vector3(0,3.15,0)*kid.scale.y)*ratio
	var foot:Vector2=camera.unproject_position(kid.global_position)*ratio
	var left:Vector2=camera.unproject_position(kid.global_position+Vector3(-.68,1.5,0)*kid.scale.y)*ratio
	var right:Vector2=camera.unproject_position(kid.global_position+Vector3(.68,1.5,0)*kid.scale.y)*ratio
	frame=Rect2(Vector2(left.x-12.,top.y-12.),Vector2(right.x-left.x+24.,foot.y-top.y+26.))
	frame.position-=get_parent().position
	queue_redraw()
func _draw() -> void:
	if frame.size.x<=0.:return
	var c:=Color("67edff") if selected==0 else Color("ff86dd")
	var a:=frame.position;var b:=frame.end;var cut:=12.
	var points:=PackedVector2Array([Vector2(a.x+cut,a.y),Vector2(b.x-cut,a.y),Vector2(b.x,a.y+cut),Vector2(b.x,b.y-cut),Vector2(b.x-cut,b.y),Vector2(a.x+cut,b.y),Vector2(a.x,b.y-cut),Vector2(a.x,a.y+cut)])
	draw_colored_polygon(points,Color(c,.035))
	points.append(points[0])
	draw_polyline(points,Color(c,.13+phase*.2),9.,true);draw_polyline(points,Color(c,.9),2.,true)
	for side in [-1.,1.]:
		var x:float=a.x if side<0 else b.x;var mid:float=(a.y+b.y)*.5
		draw_line(Vector2(x,a.y+25),Vector2(x,a.y+58),Color.WHITE,3.,true)
		var tip:=Vector2(x-side*6.,mid)
		draw_polyline(PackedVector2Array([tip+Vector2(side*13.,-11),tip,tip+Vector2(side*13.,11)]),c,3.,true)
	var center:float=frame.get_center().x
	draw_polyline(PackedVector2Array([Vector2(center-11.,a.y-16.),Vector2(center,a.y-7.),Vector2(center+11.,a.y-16.)]),c,3.,true)
static func pick(camera:Camera3D,at:Vector2,kids:Array) -> int:
	var origin:=camera.project_ray_origin(at);var end:=origin+camera.project_ray_normal(at)*40.
	var chosen:=-1;var nearest:=INF
	for i in kids.size():
		for mesh:MeshInstance3D in kids[i].find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree() or mesh.mesh==null or mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:continue
			var inverse:=mesh.global_transform.affine_inverse()
			var hit=mesh.mesh.get_aabb().intersects_segment(inverse*origin,inverse*end)
			if hit==null:continue
			var distance:float=origin.distance_to(mesh.global_transform*hit)
			if distance<nearest:nearest=distance;chosen=i
	return chosen
