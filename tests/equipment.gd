extends SceneTree
const Gear=preload("res://scripts/gear_economy.gd")
const Shops=preload("res://scripts/monument_shops.gd")
var checks:=0
var errors:=0
var app:Node
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label_value)
func shot(key:String) -> void:
	app._process(.016)
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/equipment-"+key+".png")
func run() -> void:
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var p=root.get_node("Profile"); p.gear_owned=Gear.normalized({}); p.bank=0; p.unlocked=0
	check(Gear.total_cost()==23225,"full equipment costs 23225 stars")
	check(not p.buy_gear("suit",1).ok and p.bank==0,"insufficient funds leave balance intact")
	p.bank=Gear.total_cost(); var start:int=p.bank
	check(not p.buy_gear("pack",2).ok,"cannot skip tiers")
	check(not p.buy_gear("invalid",1).ok,"invalid category rejected")
	for category in Gear.CATEGORIES:
		check(p.buy_gear(category,1).ok,"first tier purchase "+category)
		var balance:int=p.bank
		check(not p.buy_gear(category,1).ok and p.bank==balance,"duplicate purchase cannot charge "+category)
		check(not p.buy_gear(category,2).ok and p.bank==balance,"planet gate protects next tier "+category)
	p.unlocked=9
	for tier in range(2,6):
		for category in Gear.CATEGORIES: check(p.buy_gear(category,tier).ok,"tier %d %s"%[tier,category])
	check(p.bank==0 and start==Gear.total_cost(),"all fifteen purchases charge exact total")
	check(p.save("user://equipment_test.cfg")==OK,"equipment can be saved")
	var cfg:=ConfigFile.new(); cfg.load("user://equipment_test.cfg")
	check(cfg.get_value("equipment","owned")==p.gear_owned,"saved equipment retains tiers")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://equipment_test.cfg"))
	app.refresh_equipment(); app.on_action("select"); app.on_action("builder"); await shot("builder")
	check(app.state=="builder","constructor opens from crew selection")
	for slot in preload("res://scripts/suit.gd").SLOTS:
		app.on_action("slot_"+slot); check(app.state=="skin_picker","slot opens: "+slot)
		app.on_action("skin_equipment_t5"); check(p.suits[p.hero].slots[slot]=="equipment_t5","material saved: "+slot)
	app.on_action("close_gear"); check(app.state=="select","constructor returns to crew")
	app.planet=9; app.start_level(); app.begin_run()
	check(app.shield_charges==3 and app.rescue_charges==2,"full loadout initializes shields and rescues")
	var lives:int=app.lives; app.invulnerable=0; app.take_hit()
	check(app.lives==lives and app.shield_charges==2,"suit absorbs actual course damage")
	app.activate_booster("board"); check(app.board_armor==3 and app.booster_timer==15.,"board tier changes actual durability and duration")
	app.distance=2100; app.spawn_and_update(); app.finish_level()
	for i in 3:
		app.finish_walk.avatar.position=Shops.POSITIONS[i]+Vector3(0,0,3)
		app.on_action("shop_nearest"); check(app.state=="shop" and app.shop_category==Gear.CATEGORIES[i],"walk-in shop opens "+Gear.CATEGORIES[i])
		await shot("shop-"+Gear.CATEGORIES[i]); app.on_action("close_gear")
		check(app.state=="explore","shop returns to plaza")
	print("EQUIPMENT: %d checks, %d failures"%[checks,errors])
	app.free(); await process_frame; quit(1 if errors else 0)
