extends SceneTree
const Catalog=preload("res://scripts/outfit_catalog.gd")
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
	root.size=Vector2i(540,1188)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; await process_frame; app.set_process(false); app.set_physics_process(false)
	var p=root.get_node("Profile"); p.persistence_enabled=false; p.owned_items.clear(); p.outfits=[{},{}]; p.bank=0; p.unlocked=9; p.hero=0
	check(Catalog.all().size()==60,"sixty distinct stock items including ten badges")
	check(Catalog.score({})==0 and Catalog.score(Catalog.legacy({"suit":5,"pack":5,"board":5}))==1000,"efficiency spans zero to 1000")
	for world in 10:
		var count:=0
		for item:Dictionary in Catalog.all().values():
			if item.world==world: count+=1
		check(count==6,"each planet stocks armor, pack, board and a badge: "+str(world))
	check(Catalog.get_item("boots_5").world==0 and Catalog.get_item("pack_world_0").tier==5,"valuable top equipment motivates returning to easy planet")
	check(not p.buy_item("boots_5",0).ok,"insufficient funds rejected")
	p.bank=200000
	check(not p.buy_item("boots_5",1).ok,"cannot buy outside home shop")
	check(not p.wear_item("boots_5"),"unowned item cannot be equipped")
	var before:int=p.bank
	for item:Dictionary in Catalog.all().values():
		check(p.buy_item(item.id,item.world).ok,"purchase "+item.id)
		check(p.bank==before-item.price,"exact price "+item.id); before=p.bank
		check(not p.buy_item(item.id,item.world).ok and p.bank==before,"duplicate does not charge "+item.id)
	check(p.current_outfit().is_empty(),"buying does not equip")
	var max_outfit:=Catalog.legacy({"suit":5,"pack":5,"board":5})
	for id:String in max_outfit.values(): check(p.wear_item(id),"equip owned "+id)
	check(Catalog.score(p.current_outfit())==1000,"complete loadout reaches maximum score")
	p.hero=1; check(p.current_outfit().is_empty(),"second hero has separate outfit")
	check(not p.wear_item("boots_5") and p.owned_items.is_empty(),"purchases belong to one hero")
	check(p.bank==0,"second hero has a separate empty wallet")
	p.credit(5000,1); check(p.bank==5000,"reward credited to its hero")
	check(p.buy_item("boots_5",0).ok and p.wear_item("boots_5"),"second hero can buy their own copy")
	p.remove_item("boots"); check(p.current_outfit().is_empty() and p.owned_items.has("boots_5"),"remove retains hero ownership")
	p.hero=0
	check(p.save("user://equipment_test.cfg")==OK,"inventory save succeeds")
	var cfg:=ConfigFile.new(); cfg.load("user://equipment_test.cfg")
	check(cfg.get_value("equipment","items")==p.owned_items and cfg.get_value("equipment","outfits")==p.outfits,"save includes inventory and both outfits")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://equipment_test.cfg"))
	app.on_action("select"); app.on_action("builder")
	check(app.state=="shop","wardrobe opens new fitting room")
	var actual:Dictionary=p.current_outfit().duplicate(true)
	app.on_action("preview_item_helmet_1"); check(p.current_outfit()==actual,"try-on cannot change saved outfit")
	await shot("wardrobe")
	app.on_action("restore_outfit"); check(not app.trying_item,"restore shows equipped outfit")
	app.on_action("close_gear"); check(app.state=="select","wardrobe returns to selection")
	app.planet=9; app.start_level(); app.begin_run()
	check(app.shield_charges==3 and app.rescue_charges==2,"max loadout initializes defense and rescue")
	var lives:int=app.lives; app.invulnerable=0; app.take_hit()
	check(app.lives==lives and app.shield_charges==2,"armor absorbs course damage")
	app.activate_booster("board"); check(app.board_armor==3 and app.booster_timer==15.,"board changes duration and durability")
	app.distance=2100; app.spawn_and_update(); app.finish_level()
	for i in 3:
		app.finish_walk.avatar.position=Shops.POSITIONS[i]+Vector3(0,0,3)
		app.on_action("shop_nearest"); check(app.state=="shop","walk-in shop opens")
		check(app.shop_category==["suit","pack","board"][i],"correct category")
		await shot("shop-"+app.shop_category)
		app.on_action("shop_mode_galaxy"); app.on_action("shop_mode_owned"); app.on_action("shop_mode_local")
		app.on_action("fit_zoom_in"); app.on_action("fit_zoom_out")
		app.on_action("close_gear"); check(app.state=="explore","shop returns to plaza")
	print("EQUIPMENT: %d checks, %d failures"%[checks,errors])
	app.free(); await process_frame; quit(1 if errors else 0)
