extends SceneTree
const C=preload("res://scripts/course.gd")
const Pilot=preload("res://scripts/qa_route_driver.gd")
var app: Node
var failures: Array[String]=[]
func _initialize():call_deferred("run")
func run():
 var profile=root.get_node("Profile");profile.persistence_enabled=false;profile.retry_points.clear();profile.reserve_hearts.clear()
 app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
 await process_frame;app.set_process(false);app.set_physics_process(false)
 var args=OS.get_cmdline_user_args()
 var worlds=range(21)
 if args.has("--from"):worlds=range(int(args[args.find("--from")+1]),int(args[args.find("--to")+1])+1)
 if args.has("--world"):worlds=[int(args[args.find("--world")+1])]
 for world in worlds:
  var tier=preload("res://scripts/gear_economy.gd").recommended(world)
  var outfit=preload("res://scripts/outfit_catalog.gd").legacy({"suit":tier,"pack":tier,"board":tier})
  profile.outfits[profile.hero]=outfit
  for id: String in outfit.values():
   if not profile.owned_items.has(id):profile.owned_items.append(id)
  app.planet=world;app.test_layout_seed=83
  await app.start_level();await app.begin_run()
  var hits=0;var last_lives=app.lives
  for frame in 40000:
   if app.state!="run":break
   Pilot.drive(app);app.simulate(1./60)
   if frame%8==0:app._process(8./60)
   if app.lives<last_lives:hits+=last_lives-app.lives;print("HIT world=",world," s=",app.distance," lane=",app.lane," h=",app.height)
   last_lives=app.lives
   if frame%240==0:await process_frame
  print("RHYTHM world=",world," state=",app.state," distance=",app.distance," hits=",hits," lives=",app.lives)
  if app.state!="explore":failures.append(str(world))
  profile.retry_points.clear()
 print("RHYTHM FAILURES: ",failures)
 app.free();await process_frame;quit(0 if failures.is_empty() else 1)
