extends Node3D
const G=preload("res://scripts/geometry.gd")
const ROWS=[[650.,0,180.,"ВОЗВРАТ К НАЧАЛУ"],[1090.,2,4800.,"ПОЧТИ К ФИНИШУ"],[2380.,0,3220.,"ЭКСПРЕСС К ПЕТЛЯМ"],[3060.,2,1760.,"ВЧЕРАШНИЙ ПОВОРОТ"],[4860.,0,1800.,"ЕЩЁ ОДИН КРУГ"]]
var gates:Array[Dictionary]=[]
var cooldown:=0.
func setup(world:int,events:Array[Dictionary]) -> void:
	for child in get_children():get_node("/root/SceneDisposal").retire(child)
	gates.clear();cooldown=0.;visible=world==10
	if world!=10:return
	for row:Array in ROWS:
		var gate:Dictionary={"s":row[0],"lane":row[1],"target":row[2],"title":row[3],"used":false}
		var body:=Node3D.new();add_child(body);gate.node=body
		var tint:="ff8ed9" if gate.target<gate.s else "7affeb"
		var ring:=G.ring(body,1.45,1.65,Vector3(0,1.65,0));ring.rotation.x=PI*.5;ring.scale.y=1.15;ring.material_override=G.material(tint,.75)
		var mat:=ShaderMaterial.new();mat.shader=preload("res://assets/surfaces/mirror_portal.gdshader");mat.set_shader_parameter("tint",Color(tint));mat.set_shader_parameter("motion",0. if get_node("/root/Profile").reduced_motion else 1.)
		var plane:=QuadMesh.new();plane.size=Vector2(2.65,3.1);G.part(body,plane,Vector3(0,1.65,0),mat)
		var label:=G.label(body,gate.title+"\n%d м · одно применение"%gate.target,Vector3(0,4.,0),18);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		for mesh:GeometryInstance3D in body.find_children("*","GeometryInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gates.append(gate)
		for i in range(events.size()-1,-1,-1):
			var e:Dictionary=events[i]
			if absf(e.s-gate.s)<e.length*.5+24. or absf(e.s-gate.target)<e.length*.5+40.:events.remove_at(i)
func present(distance_value:float) -> void:
	for gate:Dictionary in gates:
		gate.node.position=Vector3((gate.lane-1)*2.6,0,distance_value-gate.s)
		gate.node.visible=not gate.used and absf(distance_value-gate.s)<160.
func advance(app:Node,dt:float) -> bool:
	cooldown=maxf(0.,cooldown-dt)
	if cooldown>0. or not app.loop_routes.active.is_empty():return false
	for gate:Dictionary in gates:
		if gate.used or absf(app.distance-gate.s)>2. or absf(app.x-(gate.lane-1)*2.6)>1. or app.height<-.1 or app.height>3.5:continue
		gate.used=true;cooldown=2.5
		var backward:bool=gate.target<app.distance
		app.distance=gate.target;app.lane=1;app.x=0.;app.height=0.;app.support=0.;app.support_event={};app.auto_landing=false;app.rescue_origin=0.;app.vertical_speed=0.;app.invulnerable=2.5;app.clear_gesture()
		app.record_progress()
		app.runner.position=Vector3.ZERO
		if backward:
			for route:Dictionary in app.loop_routes.routes:
				if route.start>gate.target:route.taken=false;route.passed=false
		app.spawn_and_update();app.scenery.sync(app.distance,0.,app.clock);app.update_camera()
		app.sound.sfx("whoosh");app.toast(gate.title+" · %d м"%gate.target,2.5)
		present(app.distance);return true
	return false
