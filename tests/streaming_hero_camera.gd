extends SceneTree
const Catalog=preload("res://scripts/outfit_catalog.gd")
var checks:=0
var errors:=0
func check(ok:bool,label_value:String):
 checks+=1
 if not ok:errors+=1;push_error(label_value)
func _initialize():call_deferred("run")
func run():
 var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
 await process_frame;await process_frame;app.set_process(false);app.set_physics_process(false)
 var p=root.get_node("Profile");p.persistence_enabled=false;p.wallets.clear();p.inventories.clear();p.outfits=[{},{}];p.unlocked=9;p.hero=0;p.bank=12000
 check(p.buy_item("badge_0",0).ok and p.wear_item("badge_0"),"hero zero purchases flat atom")
 p.hero=1;check(p.bank==0 and p.owned_items.is_empty() and p.current_outfit().is_empty(),"second hero inherits neither new earnings nor new purchases")
 p.bank=15000;check(p.buy_item("badge_0",0).ok,"second hero buys independent copy")
 p.hero=0;check(p.bank==8500 and p.current_outfit().badge=="badge_0","first wallet and outfit preserved")
 p.credit(43,1);check(p.bank==8500,"other hero's reward cannot enter current wallet")
 p.hero=1;check(p.bank==11543,"reward reaches the owner")
 p.hero=2;check(p.bank==0 and p.current_outfit().is_empty(),"future hero starts isolated")
 p.hero=0
 check(p.save("user://hero_wallet_test.cfg")==OK,"hero ledgers save")
 var cfg:=ConfigFile.new();cfg.load("user://hero_wallet_test.cfg")
 check(cfg.get_value("heroes","wallets")==p.wallets and cfg.get_value("heroes","inventories")==p.inventories,"all hero ledgers persist")
 DirAccess.remove_absolute(ProjectSettings.globalize_path("user://hero_wallet_test.cfg"))
 for shape in 10:
  var badge=preload("res://scripts/chest_badge.gd").build(shape)
  var mesh:MeshInstance3D=badge.get_child(0)
  check(mesh.mesh is QuadMesh and mesh.mesh.size.x<.53 and mesh.mesh.size.y<.35 and mesh.material_override.albedo_texture!=null,"flat texture fits chest square: "+str(shape));badge.free()
 var cache=preload("res://scripts/planet_cache.gd");cache.request(0)
 var frames:=0
 while not cache.ready(0):await process_frame;frames+=1
 cache.collect(0)
 app.configured_planet=-1;app.planet=0;app.configure_planet()
 check(not app.finish.visible and app.finish.position.z==-2100.,"newly selected planet cannot draw its entire finish city behind the menu")
 check(cache.scenery[0].chunks.size()==77,"offline natural landscape covers the complete route")
 var landscape:Node3D=cache.scenery[0].chunks[2].instantiate()
 check(landscape.get_meta("natural_landmark_kind")=="crystal_gardens","large natural landmarks replace roadside houses");landscape.free()
 app.start_level();app.begin_run();app.distance=2100.;app.spawn_and_update();app.finish_level()
 var walk:Node3D=app.finish_walk
 var a:=InputEventScreenTouch.new();a.index=0;a.position=Vector2(180,400);a.pressed=true;walk.pointer_event(a)
 a=InputEventScreenTouch.new();a.index=1;a.position=Vector2(300,400);a.pressed=true;walk.pointer_event(a)
 var drag:=InputEventScreenDrag.new();drag.index=1;drag.position=Vector2(420,400);walk.pointer_event(drag)
 check(is_equal_approx(walk.zoom,2.),"pinch enlarges character by two times")
 walk.stop();walk.zoom=1.9;walk.yaw=0.;walk.pitch=.2
 var blocker:=StaticBody3D.new();app.track_root.add_child(blocker);blocker.position=Vector3(walk.avatar.position.x,2.5,6.)
 var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(4,5,1);collision.shape=box;blocker.add_child(collision)
 await physics_frame;await physics_frame
 walk.present(.1,app.runner,app.camera,true)
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=walk.camera_shape;query.transform=Transform3D(Basis.IDENTITY,app.camera.position);query.collision_mask=1;query.exclude=[walk.avatar.get_rid()]
 check(walk.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"camera volume stays outside objects")
 check(app.camera.position.distance_to(app.runner.position+Vector3(0,1.4,0))>1.4,"camera cannot enter the hero")
 check(app.get_node("Sun0").shadow_enabled and app.runner.face.skin.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"real directional shadows are restored")
 print("STREAMING / HERO WALLETS / DECALS / CAMERA: ",checks," checks, ",errors," failures")
 if is_instance_valid(app.mobile_presentation):app.mobile_presentation.free()
 else:app.free()
 await process_frame;quit(1 if errors else 0)
