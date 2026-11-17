extends SceneTree
const C=preload("res://scripts/course.gd")
const Loops=preload("res://scripts/loop_routes.gd")
const CarCatalog=preload("res://scripts/space_car_catalog.gd")
var failures: Array[String]=[]
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
 if not ok:failures.append(label);push_error(label)
func run():
 var loops=Loops.new();root.add_child(loops)
 check(preload("res://scripts/planets.gd").count()==20,"twenty planets visible in campaign")
 var names={}
 var car_styles={}
 for world in range(0,41):
  check(int(preload("res://scripts/planet_visual.gd").surface(world).get_shader_parameter("identity"))==preload("res://scripts/planets.gd").style_index(world),"orbital biome follows world style")
  var planet_name: String=preload("res://scripts/planets.gd").get_data(world).name
  if world<20:
   check(not names.has(planet_name),"unique name: "+planet_name)
   names[planet_name]=true
  check(world==0 or C.speed_scale(world)>C.speed_scale(world-1),"speed increases at "+str(world))
  check(world==0 or C.length_for(world)>=C.length_for(world-1),"course does not shrink at "+str(world))
  for seed_value in [0,83,4129]:
   C.layout_seed=seed_value
   preload("res://scripts/loop_layout.gd").route_seed=seed_value
   var events=C.events(world);var pickups=C.stars(world,events)
   loops.setup(world,seed_value);loops.reserve(events,pickups)
   preload("res://scripts/upper_route.gd").install(events,pickups,world)
   for i in range(events.size()-1,-1,-1):
    if not events[i].kind.begins_with("upper_") and absf(events[i].s-C.length_for(world)*.5)<events[i].length*.5+28.:events.remove_at(i)
   C.clean_reserved_routes(events,pickups)
   check(loops.routes.size()>=2,"loops remain on every world")
   var kinds={}
   for e in events:kinds[e.kind]=true
   check(kinds.size()>=12,"diverse mechanics on "+str(world))
   check(kinds.has("tunnel") and kinds.has("upper_deck") and kinds.has("basement"),"vertical routes survive reservations on "+str(world))
   for pickup in pickups:
    check(pickup.requirement.is_empty() or pickup.has("anchor"),"conditional reward retains its obstacle")
   for e in events:
    if e.kind=="space_car":car_styles[e.car_style]=true
    if e.kind not in ["exp_ufo","space_car"]:continue
    var origin: float=e.origin
    C.advance_event(e,origin-60.,C.expected_speed(origin,world),world,0.)
    var before: float=e.s
    C.advance_event(e,origin-59.,C.expected_speed(origin,world),world,1./30.)
    check(e.s<before and e.speed<0.,"UFO actually travels along the road")
   if world>=11:check(kinds.has("exp_ufo") and not kinds.has("truck") and not kinds.has("traffic"),"UFO and car traffic coexist on "+str(world))
 check(CarCatalog.NAMES.size()==25 and car_styles.size()==CarCatalog.NAMES.size(),"all 25 car models occur in courses")
 var first_order:=CarCatalog.shuffled_order(83,3)
 check(first_order!=CarCatalog.shuffled_order(84,3) and first_order==CarCatalog.shuffled_order(83,3),"traffic seed changes model order reproducibly")
 var distinct={}
 for style in first_order:distinct[style]=true
 check(distinct.size()==CarCatalog.NAMES.size(),"traffic draws each model once before repeating")
 for style in CarCatalog.NAMES.size():
  var car_event=C.make_event(180.,1,"space_car");car_event.car_style=style
  var car=preload("res://scripts/space_car.gd").build(car_event,19);root.add_child(car)
  await process_frame
  preload("res://scripts/space_car.gd").present(car,car_event,1.,false)
  check(is_instance_valid(car.get_meta("indicator")),"car signal survives static mesh batching")
  check(car.get_meta("pilot").character_index==20,"original alien drives car "+str(style))
  car.free()
 var e=C.make_event(180.,1,"exp_ufo")
 var ufo=preload("res://scripts/expedition_props.gd").build(e,11);root.add_child(ufo)
 check(ufo.get_meta("pilot").character_index==preload("res://scripts/crew.gd").ALIEN_GUY,"pilot is the actual green plaza character")
 ufo.free();loops.free()
 print("RHYTHM CONTRACT: ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
