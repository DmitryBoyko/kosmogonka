extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
 await process_frame;await process_frame;app.set_process(false);app.set_physics_process(false)
 var cache=load("res://scripts/planet_cache.gd")
 cache.request(1)
 while not cache.ready(1): await process_frame
 cache.collect(1);app.planet=1;app.configure_planet();app.start_level()
 print("COSTS ", app.transition_costs)
 app.mobile_presentation.free();await process_frame;quit()
