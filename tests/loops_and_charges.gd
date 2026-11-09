extends SceneTree
const Loops=preload("res://scripts/loop_routes.gd")
const B=preload("res://scripts/booster_catalog.gd")
const Course=preload("res://scripts/course.gd")
var checks:=0
var errors:Array[String]=[]
var app:Node
class BrokenProfile:
	extends "res://scripts/profile.gd"
	func save(_path:String=PATH) -> int: return ERR_CANT_CREATE
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value); push_error(label_value)
func shot(name_value:String) -> void:
	if DisplayServer.get_name()=="headless": return
	app._process(.016); await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/new-"+name_value+".png")
func run() -> void:
	root.size=Vector2i(540,1188)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var p=root.get_node("Profile"); p.persistence_enabled=false; p.hero=0; p.charges.clear(); p.booster_training.clear(); p.wallets={}; p.unlocked=9
	check(p.grant_booster_training(),"one-time training supply")
	check(not p.grant_booster_training() and p.charge_count("jet")==1,"training cannot be farmed by restarting")
	p.hero=1; check(p.charge_count("jet")==0,"second hero starts with own inventory"); p.hero=0
	check(not p.buy_charge("jet",0).ok,"no purchase without money")
	p.bank=1000; var before:int=p.bank
	check(p.buy_charge("jet",0).ok and p.bank==before-24 and p.charge_count("jet")==2,"purchase charges exact wallet once")
	check(not p.change_charge("unknown",-1),"unknown type rejected")
	p.charges["0"]["jet"]=9; before=p.bank
	check(not p.buy_charge("jet",0).ok and p.bank==before,"full inventory cannot charge wallet")
	check(p.save("user://charges-review.cfg")==OK,"new inventory saves")
	var cfg:=ConfigFile.new(); cfg.load("user://charges-review.cfg")
	check(cfg.get_value("heroes","charges")==p.charges and cfg.get_value("heroes","booster_training")==p.booster_training,"charges and training persist per hero")
	var reloaded=load("res://scripts/profile.gd").new(); reloaded.load_charge_state(cfg)
	check(reloaded.charge_count("jet")==9 and reloaded.booster_training.has("0"),"real load path restores the saved stock and tutorial flag")
	reloaded.hero=1; check(reloaded.charge_count("jet")==0,"load preserves another hero's independent stock")
	reloaded.load_charge_state(ConfigFile.new()); check(reloaded.charges.is_empty() and reloaded.booster_training.is_empty(),"legacy save receives empty independent stocks")
	reloaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://charges-review.cfg"))
	var broken:=BrokenProfile.new(); broken.bank=100; broken.charges={"0":{"jet":1}}
	check(not broken.buy_charge("jet",0).ok and broken.bank==100 and broken.charge_count("jet")==1,"failed save rolls purchase back")
	check(not broken.change_charge("jet",-1) and broken.charge_count("jet")==1,"failed save cannot spend a charge")
	check(not broken.grant_booster_training() and broken.booster_training.is_empty(),"failed save cannot mark training redeemed")
	broken.free()
	for kind:String in B.KINDS:
		check(Loops.point(kind,0.).is_equal_approx(Vector3.ZERO) and Loops.point(kind,1.).is_equal_approx(Vector3(0,0,-55)),"continuous branch endpoints "+kind)
		check(Loops.arcs(kind)[-1]>100. and Loops.arcs(kind)[-1]<160.,"modestly longer bonus branch "+kind)
		for i in range(1,160):
			var frame:=Loops.frame(kind,i/160.)
			check(absf(frame.forward.dot(frame.up))<.001 and is_finite(frame.up.x),"valid support frame "+kind)
	for world in 10:
		app.planet=world; app.reset_course(); app.begin_run()
		check(not app.events.any(func(e):return e.kind in ["jet","board"]),"no unlimited automatic boosters "+str(world))
		for route:Dictionary in app.loop_routes.routes:
			var kind:String=route.kind
			p.charges["0"]={"jet":3,"board":3}
			var start:float=route.start; app.distance=start-.2; app.lane=route.lane; app.x=(route.lane-1)*2.6; app.height=0.; app.booster=""; app.tunnel_active={}; app.basement_active={}
			check(app.use_charge(kind) and p.charge_count(kind)==2,"manual activation spends one "+str(world)+kind)
			check(not app.use_charge(kind) and p.charge_count(kind)==2,"repeat press cannot spend again "+kind)
			var stars_before:int=app.stars
			app.simulate(.016)
			check(not app.loop_routes.active.is_empty(),"chosen boosted lane enters "+str(world)+kind)
			check(not app.can_act(),"normal swipe cannot eject player into empty space")
			var paused_distance:float=app.distance
			app.pause_game(); app._physics_process(.5)
			check(is_equal_approx(app.distance,paused_distance),"pause freezes branch")
			app.state="run"; app.sound.set_paused(false); app.hud.playing()
			var frames:=0; var previous:float=app.distance
			while not app.loop_routes.active.is_empty() and frames<1400:
				app.simulate(.016); frames+=1
				check(app.distance>=previous,"main-road progress cannot reverse")
				previous=app.distance
				if frames%12==0 and not app.loop_routes.active.is_empty():
					app.update_camera(.016)
					for body_y in [0.,2.97]:
						var pixel:Vector2=app.camera.unproject_position(app.runner.to_global(Vector3(0,body_y,0)))
						check(Rect2(Vector2(8,120),Vector2(524,920)).has_point(pixel),"complete hero visible around loop %s world%d frame%d y%.2f pixel%s u%.3f"%[kind,world,frames,body_y,str(pixel),app.loop_routes.active.u])
				if world<2 and frames in [90,160,230]: await shot(kind+"-"+str(frames))
			check(frames<1400 and absf(app.distance-(start+55.))<.01,"branch returns at correct endpoint "+kind)
			check(app.stars-stars_before==72,"all rewards exactly once "+kind)
			check(p.charge_count(kind)>=2 and app.booster.is_empty(),"no second charge and safe dismount "+kind)
			check(app.runner.position.z==0. and app.height==0.,"grounded return "+kind)
			check(not app.loop_routes.try_enter(start,app.x,0,kind),"taken branch cannot pay again")
			app.hud.playing(); app.update_hud()
			if world<2: await shot(kind+"-exit")
		check(not app.loop_routes.try_enter(400.,0.,0.,""),"unboosted straight bypass always available")
	for seed_value in 100:
		for world in 10:
			var drops:=B.drops(seed_value,world)
			check(drops.size()<=2 and drops==B.drops(seed_value,world),"bounded reproducible rare supply")
	app.planet=0; app.reset_course(); app.begin_run(); app.distance=660.; app.lane=0; app.x=-2.6; app.height=0.; app.booster=""
	for preview:Node3D in app.previews: preview.hide()
	app.events.assign([Course.make_event(660.,1,"tunnel")]); app.pickups.clear(); app.runner.position=Vector3(-2.6,0,0); app.spawn_and_update(); await shot("corridor-bypass")
	app.gear_context="explore"; app.shop_category="boost"; app.selected_item="jet"; app.show_outfit_shop(); await shot("boost-shop")
	app.shop_category="pack"; app.shop_mode="galaxy"; app.selected_item="pack_world_0"; app.show_outfit_shop(); await shot("shop")
	print("LOOPS / CHARGES: %d checks, %d failures"%[checks,errors.size()])
	app.free(); await process_frame; quit(0 if errors.is_empty() else 1)
