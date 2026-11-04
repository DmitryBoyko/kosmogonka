extends SceneTree
const Course=preload("res://scripts/course.gd")
func _initialize():call_deferred("run")
func run():
 var checks:=0;var errors:=0
 for seed_value in [0,17,98431]:
  Course.layout_seed=seed_value
  for world in 10:
   var events:=Course.events(world);var base:Array=events.filter(func(event):return not event.get("surprise",false))
   var candidates:Array[float]=[]
   for distance_value in range(210,2020,4):
    var safe:=not Course.transitioning(distance_value) and not (distance_value>Course.FRONT_START-35 and distance_value<Course.FRONT_END+Course.TRANSITION+35)
    for event:Dictionary in base:
     var clearance:float=event.length*.5+14
     if event.kind in ["stairs","stairs_down","skycarrier","basement","tunnel"]:clearance+=28
     if event.kind in ["ramp","carrier","stairs","stairs_down","skycarrier"] and distance_value>event.s-event.length*.5-25 and distance_value<event.s+event.length*.5+100:safe=false;break
     if absf(distance_value-event.s)<clearance:safe=false;break
    if safe:candidates.append(float(distance_value))
   var rng:=RandomNumberGenerator.new();rng.seed=seed_value+world*9283+461
   var reference:Array[float]=[];var count:=2+world*2
   while count>0 and not candidates.is_empty():
    var s:float=candidates[rng.randi_range(0,candidates.size()-1)];reference.append(s)
    rng.randf();candidates=candidates.filter(func(value):return absf(value-s)>28.);count-=1
   var actual:Array[float]=[]
   for event:Dictionary in events:
    if not event.get("surprise",false):continue
    var partner:=false
    if world>=4:
     for original:Dictionary in base:
      if original.kind=="alien" and is_equal_approx(event.s,original.s+5.):partner=true;break
    if not partner:actual.append(float(event.s))
   actual.sort();reference.sort();checks+=1
   if actual!=reference:errors+=1;push_error("Courier layout changed: "+str(world)+" "+str(seed_value))
 print("COURIER OPTIMIZATION: ",checks," checks, ",errors," failures");quit(1 if errors else 0)
