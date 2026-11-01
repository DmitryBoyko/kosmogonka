extends SceneTree
const Hero=preload("res://scripts/hero.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_value: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label_value)
func run() -> void:
	var hero=Hero.new()
	root.add_child(hero)
	hero.build(false)
	check(hero.jet_fx.jets.size()==2,"two independent engine plumes")
	hero.animate(0.1,"idle")
	check(not hero.jet_fx.jets[0].visible and hero.jet_fx.power==0,"inactive booster has no exhaust")
	for i in 20: hero.animate(1.0/60,"jet")
	check(hero.jet_fx.jets[0].visible and hero.jet_fx.power>0.99,"jet ignition reaches full power")
	check(hero.jet_fx.materials[0].get_shader_parameter("flow_time")>0.3,"plume turbulence receives simulation time")
	var time_before: float=hero.jet_fx.flow_time
	hero.animate(0,"jet")
	check(hero.jet_fx.flow_time==time_before,"zero time freezes the plume on pause")
	check(hero.jet_fx.lights[0].light_energy>0,"active engines illuminate the suit")
	check(hero.jet_fx.materials[0]!=hero.jet_fx.materials[1],"engines have independent pressure phases")
	check(hero.jet_fx.jets[0].position.y<0.77,"exhaust starts at the nozzle exit")
	hero.animate(0.016,"run",18)
	check(not hero.jet_fx.jets[0].visible and hero.jet_fx.lights[0].light_energy==0,"stopping the booster removes flame and light")
	hero.free()
	print("JETPACK: %d checks, %d failures" % [checks,failures])
	await process_frame
	quit(1 if failures else 0)
