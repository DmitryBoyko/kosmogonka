extends SceneTree
const C=preload("res://scripts/course.gd")
var app:Node
var checks:=0
var errors:Array[String]=[]
class BrokenProfile:
	extends "res://scripts/profile.gd"
	func save(_path:String=PATH) -> int:return ERR_CANT_CREATE
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok:errors.append(label_value);push_error(label_value)
func shot(name_value:String) -> void:
	if DisplayServer.get_name()=="headless":return
	if name_value in ["triple","double_board"]:app.pickup_feedback.reset();app.invulnerable=0.
	app._process(.016)
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/mirror-"+name_value+".png")
func swipe_crew(direction:int) -> void:
	app._process(.016);await process_frame
	for pressed in [true,false]:
		var event:=InputEventScreenTouch.new();event.index=0;event.position=Vector2(270+(85 if pressed else -85)*direction,525);event.pressed=pressed;root.push_input(event,true);await process_frame
func run() -> void:
	root.size=Vector2i(540,1188);app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.persistence_enabled=false;p.first_person=false;p.retry_points.clear();p.reserve_hearts.clear();p.unlocked=10;p.hero=0;p.bank=600
	app.show_menu();app.on_action("select");await swipe_crew(1);check(p.hero==1,"swipe selects the next crew member")
	await swipe_crew(-1);check(p.hero==0,"swipe selects the previous crew member")
	check(app.previews.all(func(actor):return not actor.visible),"original pair is hidden")
	check(not app.hud.screen.find_children("*","Button",true,false).any(func(b):return b.get_meta("command","") in ["boy","girl","builder"]),"no gender or pre-run shop buttons")
	app.on_action("builder");check(app.state=="select","pre-run shop action is blocked")
	await shot("selection")
	check(p.buy_heart(0).ok and p.heart_count()==1 and p.bank==450,"heart costs 150 stars")
	p.hero=1;check(p.heart_count()==0,"heart inventory belongs to selected hero");p.hero=0
	check(p.buy_heart(0).ok and p.buy_heart(0).ok and not p.buy_heart(0).ok and p.heart_count()==3,"at most three reserve hearts")
	var path:="user://mirror-profile-test.cfg";check(p.save(path)==OK,"hearts and retry save")
	var cfg:=ConfigFile.new();cfg.load(path);check(cfg.get_value("heroes","reserve_hearts",{}).get("0")==3,"heart inventory persists");DirAccess.remove_absolute(path)
	var broken:=BrokenProfile.new();broken.bank=200;check(not broken.buy_heart(0).ok and broken.bank==200 and broken.heart_count()==0,"failed save rolls heart purchase back");broken.reserve_hearts["0"]=1;check(not broken.consume_heart() and broken.heart_count()==1,"failed save cannot consume a reserve heart");broken.free()
	app.planet=0;app.start_level();app.begin_run();app.shield_charges=0;app.rescue_charges=0;app.booster="";app.invulnerable=0.;app.take_hit()
	check(app.lives==3 and p.heart_count()==2,"one reserve heart restores exactly one lost life")
	app.invulnerable=1.;app.take_hit();check(p.heart_count()==2,"invulnerability cannot consume a heart")
	p.reserve_hearts.clear()
	for world in 11:
		p.retry_points.clear();app.planet=world;app.start_level();app.begin_run();app.distance=C.length_for(world)*.49;app.show_results(false);app.start_level();app.begin_run();check(app.distance==0.,"first-half defeat restarts from beginning world"+str(world))
		app.distance=C.length_for(world)*.61;app.show_results(false);app.start_level();app.begin_run();check(is_equal_approx(app.distance,C.length_for(world)*.5) and app.lives==3,"second-half defeat restores midpoint and three hearts world"+str(world))
		check(app.find_support()==0.,"checkpoint respawns on clear ground world"+str(world))
		if world==10:
			check(p.save(path)==OK,"midpoint checkpoint saves")
			cfg=ConfigFile.new();cfg.load(path);check(cfg.get_value("heroes","retry_points",{}).get("0:10",{}).get("distance",0.)==2600.,"midpoint is persistent and bound to hero/planet");DirAccess.remove_absolute(path)
		p.retry_points.clear()
		app.start_zone.configure(world);check(app.start_zone.themes.has(world),"unique launch identity world"+str(world))
		var launch:Node3D=app.start_zone.themes[world].get_node("LaunchSpaceKit")
		var district:Node3D=app.finish.get_node("MonumentSpaceKit")
		check(launch.get_child_count()>=3 and district.get_child_count()>=3,"themed Space Kit landmarks world "+str(world))
		var sites:Node3D=app.roadside_settlements
		check(sites.sites.size() in [2,3,4],"sparse roadside settlements world "+str(world))
		for i in sites.sites.size():
			var clearing:AABB=sites.clearings[i]
			check(clearing.position.x>5. or clearing.end.x< -5.,"settlements stay beyond the roadway")
			if i>0:
				check(sites.sites[i].s-sites.sites[i-1].s>262.,"at most one settlement renders in the current window")
		check(app.scenery.horizon_patches.size()==4,"distant terrain surrounds the detailed track")
		for unit:Node3D in launch.get_children():
			for piece:MeshInstance3D in unit.find_children("*","MeshInstance3D",true,false):
				var bounds:=unit.transform*piece.transform*piece.get_aabb()
				check(bounds.end.x< -4.5 or bounds.position.x>4.5,"launch art clears running lanes world "+str(world))
		if app.finish.has_meta("cached_collision_shapes"):
			var collision_count:int=app.finish.get_meta("cached_collision_shapes").size()
			check(collision_count>district.get_child_count(),"cached finish includes district shapes world "+str(world))
		p.retry_points.clear();app.reset_course();app.begin_run();app.distance=0.;app._process(.016);await shot("start-%02d"%world)
	check(app.start_zone.themes.size()==11,"eleven different launch scenes")
	app.planet=10;app.start_level();app.begin_run();p.charges["0"]={"jet":9,"board":9}
	check(app.loop_routes.routes.size()==7,"mirror world has seven loop routes")
	for route:Dictionary in app.loop_routes.routes:
		app.distance=route.start;app.lane=route.lane;app.x=(route.lane-1)*2.6;app.height=0.;app.booster="";app.use_charge(route.booster);app.simulate(.016)
		check(not app.loop_routes.active.is_empty(),"enter mirror loop "+route.kind)
		if route.kind in ["triple","double_board"]:
			app.loop_routes.travelled=app.loop_routes.arcs(route.kind)[70];app.simulate_loop(0.);await shot(route.kind)
		for first_person:bool in [false,true]:
			p.first_person=first_person
			var visible_samples:=0
			for index:int in [46,75,105]:
				app.loop_routes.travelled=app.loop_routes.arcs(route.kind)[index]
				app.simulate_loop(0.)
				app._process(.016)
				var pulse:MeshInstance3D=route.pulse
				var point:Vector2=app.camera.unproject_position(pulse.global_position)
				if pulse.visible and not app.camera.is_position_behind(pulse.global_position) and app.camera.get_viewport().get_visible_rect().has_point(point):
					visible_samples+=1
			check(visible_samples>=2,"loop core pulse is readable at speed: "+route.kind+" first person "+str(first_person))
		p.first_person=false
		for i in 2400:
			if app.loop_routes.active.is_empty():break
			app.simulate(.016)
		check(route.taken and app.loop_routes.active.is_empty() and app.lives==3,"complete mirror loop "+route.kind)
		await process_frame
	app.booster="";app.height=0.;app._process(.016);await shot("loops")
	app.distance=630.;app.x=-2.6;app.lane=0;app._process(.016);await shot("portal")
	var portal = app.mirror_portals.gates[0].vortex
	check(portal.mesh.size.y>5. and portal.material_override.get_shader_parameter("energy_time")>0.,"portal has a tall animated accretion disk")
	app.mirror_portals.present(app.distance,app.turn_track,app.clock,true)
	check(is_zero_approx(float(portal.material_override.get_shader_parameter("energy_time"))),"reduced motion freezes portal currents")
	var core: Node3D = app.loop_routes.routes[0].node.get_node("EnergyCore")
	core.advance(2.5,false)
	check(core.rays.multimesh.instance_count==8 and core.orbit.mesh.size.x>7. and is_equal_approx(core.heart.material_override.get_shader_parameter("energy_time"),2.5),"plasma and lightning are batched at the loop core")
	for gate:Dictionary in app.mirror_portals.gates:
		app.mirror_portals.cooldown=0.;app.distance=gate.s;app.x=(gate.lane-1)*2.6;app.height=0.;var before:int=app.stars
		check(app.mirror_portals.advance(app,.016) and app.distance==gate.target and gate.used,"portal reaches advertised destination "+gate.title)
		check(app.stars==before,"portal never duplicates star rewards")
		check(app.mirror_portals.arrival.visible,"teleport shows a short arrival wave")
		app.mirror_portals.present(app.distance,app.turn_track,app.clock+.68,false)
		check(not app.mirror_portals.arrival.visible,"arrival wave expires")
		app.mirror_portals.cooldown=0.;app.distance=gate.s;app.x=(gate.lane-1)*2.6
		check(not app.mirror_portals.advance(app,.016),"portal can only be used once")
	app.distance=180.;app.show_results(false);check(p.retry_points.get("0:10",{}).get("distance",0.)==2600.,"return portal cannot erase an already activated midpoint")
	app.start_level();app.begin_run();app.distance=C.length_for(10);app.finish_level();check(app.state=="explore" and app.shop_visitors.visitors.size() in [1,2,3],"one to three shop visitors spawn after finishing")
	for v:Dictionary in app.shop_visitors.visitors:
		for other:Dictionary in app.shop_visitors.visitors:
			if other!=v:check(v.home.distance_to(other.home)>10.,"shopper paths cannot overlap")
		check(v.eyes.size()==3 and not v.eyes[0].get_children().is_empty(),"three visible animated visitor eyes")
		var before:Vector3=v.eyes[0].position;app.shop_visitors.advance(.5);check(before!=v.eyes[0].position,"visitor eyes orbit")
	if DisplayServer.get_name()!="headless" and not app.shop_visitors.visitors.is_empty():
		var v:Dictionary=app.shop_visitors.visitors[0]
		app.camera.global_position=v.node.global_position+v.node.global_basis.z*3.6+v.node.global_basis.x*1.8+Vector3.UP*1.8;app.camera.look_at(v.node.global_position+Vector3(0,1.4,0));app.camera.fov=48.
		await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/mirror-visitor.png")
	app.gear_context="explore";app.shop_category="boost";app.shop_mode="local";app.selected_item="heart";app.state="shop";app.show_outfit_shop();app._process(.016);await shot("hearts")
	print("MIRROR / SELECTION / HEARTS / CHECKPOINTS: %d checks, %d failures"%[checks,errors.size()])
	app.queue_free();await process_frame;await process_frame;quit(0 if errors.is_empty() else 1)
