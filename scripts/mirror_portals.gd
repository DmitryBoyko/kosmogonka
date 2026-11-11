extends Node3D
const G=preload("res://scripts/geometry.gd")
const FX=preload("res://scripts/energy_effects.gd")
const ROWS=[[650.,0,180.,"ВОЗВРАТ К НАЧАЛУ"],[1090.,2,4800.,"ПОЧТИ К ФИНИШУ"],[2380.,0,3220.,"ЭКСПРЕСС К ПЕТЛЯМ"],[3060.,2,1760.,"ВЧЕРАШНИЙ ПОВОРОТ"],[4860.,0,1800.,"ЕЩЁ ОДИН КРУГ"]]
var gates:Array[Dictionary]=[]
var cooldown:=0.
var arrival: MeshInstance3D
var arrival_time := -1.
var arrival_s := 0.
func setup(world:int,events:Array[Dictionary]) -> void:
	for child in get_children():get_node("/root/SceneDisposal").retire(child)
	gates.clear();cooldown=0.;visible=world==10
	arrival=null;arrival_time=-1.
	if world!=10:return
	for row:Array in ROWS:
		var gate:Dictionary={"s":row[0],"lane":row[1],"target":row[2],"title":row[3],"used":false}
		var body:=Node3D.new();add_child(body);gate.node=body
		var tint:="ff8ed9" if gate.target<gate.s else "7affeb"
		var center := Vector3(0,2.19,0)
		var ring:=G.ring(body,1.53,1.75,center,"354258")
		ring.rotation.x=PI*.5;ring.scale.z=1.19
		var circuit:=G.ring(body,1.62,1.67,center+Vector3.BACK*.088,tint,.62)
		circuit.rotation.x=PI*.5;circuit.scale.z=1.19
		var vortex:=FX.vortex(body,Vector2(4.55,5.55),center+Vector3.BACK*.145,Color(tint))
		vortex.name="PortalVortex"
		vortex.material_override.set_shader_parameter("axis",-1. if gate.target<gate.s else 1.)
		gate.vortex=vortex
		var label:=G.label(body,gate.title+"\n%d м · одно применение"%gate.target,Vector3(0,4.85,0),18);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		for mesh:GeometryInstance3D in body.find_children("*","GeometryInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gates.append(gate)
		for i in range(events.size()-1,-1,-1):
			var e:Dictionary=events[i]
			if absf(e.s-gate.s)<e.length*.5+24. or absf(e.s-gate.target)<e.length*.5+40.:events.remove_at(i)
func present(distance_value:float,track:RefCounted=null,clock:float=0.,reduced:bool=false) -> void:
	for gate:Dictionary in gates:
		var local:=Vector3((gate.lane-1)*2.6,0,distance_value-gate.s)
		gate.node.position=track.map(local) if track else local
		gate.node.rotation.y=track.heading(gate.s) if track else 0.
		gate.node.visible=not gate.used and absf(distance_value-gate.s)<160.
		if gate.node.visible:
			gate.vortex.material_override.set_shader_parameter("energy_time",0. if reduced else clock)
	if is_instance_valid(arrival):
		var phase := (clock-arrival_time)/.64
		arrival.visible = not reduced and phase>=0. and phase<1.
		if arrival.visible:
			var local := Vector3(0,2.15,distance_value-arrival_s)
			arrival.position = track.map(local) if track else local
			arrival.rotation.y = track.heading(arrival_s) if track else 0.
			arrival.material_override.set_shader_parameter("burst",phase)
			arrival.material_override.set_shader_parameter("energy_time",clock)
func advance(app:Node,dt:float) -> bool:
	cooldown=maxf(0.,cooldown-dt)
	if cooldown>0. or not app.loop_routes.active.is_empty():return false
	for gate:Dictionary in gates:
		if gate.used or absf(app.distance-gate.s)>2. or absf(app.x-(gate.lane-1)*2.6)>1. or app.height<-.1 or app.height>3.5:continue
		gate.used=true;cooldown=2.5
		var backward:bool=gate.target<app.distance
		if not get_node("/root/Profile").reduced_motion:
			if not is_instance_valid(arrival):
				arrival = FX.vortex(self,Vector2(8.5,8.5),Vector3.ZERO,Color.WHITE)
				arrival.name = "PortalArrivalWave"
			arrival.material_override.set_shader_parameter("tint",Color("ff8ed9") if backward else Color("7affeb"))
			arrival_s = gate.target+7.
			arrival_time = app.clock
		app.distance=gate.target;app.lane=1;app.x=0.;app.height=0.;app.support=0.;app.support_event={};app.auto_landing=false;app.rescue_origin=0.;app.vertical_speed=0.;app.invulnerable=2.5;app.clear_gesture()
		app.booster_star_jump=false
		app.record_progress()
		app.runner.position=Vector3.ZERO
		if backward:
			for route:Dictionary in app.loop_routes.routes:
				if route.start>gate.target:route.taken=false;route.passed=false
		app.spawn_and_update();app.scenery.sync(app.distance,0.,app.clock);app.update_camera()
		app.sound.sfx("whoosh");app.toast(gate.title+" · %d м"%gate.target,2.5)
		present(app.distance,app.turn_track,app.clock,get_node("/root/Profile").reduced_motion);return true
	return false
