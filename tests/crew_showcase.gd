extends SceneTree

const Showcase = preload("res://scripts/crew_showcase.gd")
const Crew = preload("res://scripts/crew.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func shot(key: String) -> void:
	if DisplayServer.get_name()=="headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/showcase-"+key+".png")

func run() -> void:
	root.size=Vector2i(540,960)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var profile = root.get_node("Profile")
	profile.hero=0
	profile.reduced_motion=false
	app.show_menu()
	app.on_action("select")
	var carousel: Node3D=app.carousel
	var stage: RefCounted=carousel.showcase
	app._process(.016)
	var actor: Node3D=carousel.cards[0]
	var rig: Skeleton3D=actor.skeleton
	var head:=rig.find_bone("head")
	var maximum := 0.
	var worst_step := 0.
	var previous:=Quaternion.IDENTITY
	stage.wait=100.
	for frame in 510:
		app._process(1./60.)
		var current:=rig.get_bone_pose_rotation(head)
		maximum=maxf(maximum,current.angle_to(Quaternion.IDENTITY))
		worst_step=maxf(worst_step,current.angle_to(previous))
		previous=current
	check(maximum>.045 and maximum<.13 and worst_step<.014,"subtle gaze changes and pauses at rest")
	await shot("idle")
	stage.wait=.016
	app._process(.02)
	check(stage.time>=0.,"exchange starts automatically on selection")
	for direction in [-1,1]:
		for initiator in 2:
			stage.start(0,direction,initiator)
			var other: Node3D=carousel.cards[posmod(direction,Crew.MODELS.size())]
			var away := [false,false]
			var fired := [false,false]
			for frame in 414:
				app._process(1./60.)
				for i in 2:
					var card: Node3D = actor if i==0 else other
					if card.position.y>.28: away[i]=true
					var fx := card.get_node_or_null("ShowcaseJet")
					if fx and fx.jets[0].visible: fired[i]=true
				if direction==1 and initiator==0 and frame in [45,88,217,263]:
					await shot("exchange-%d"%frame)
			check(stage.contacts==2 and away==[true,true] and fired==[true,true],"both actors react, fire jets and return")
			check(stage.time<0. and absf(actor.position.x)<.025 and absf(other.position.x-direction*2.65)<.025,"actors return to carousel positions")
			check(is_equal_approx(actor.scale.x,1.15),"selected hero retains display size")
	stage.start(0,1,0)
	for frame in 91: app._process(1./60.)
	app.step_crew(1)
	for frame in 20: app._process(1./60.)
	check(profile.hero==1 and stage.time<0. and stage.weight==0.,"navigation cancels the scene and keeps selection")
	stage.start(1,1,0)
	for frame in 82: app._process(1./60.)
	app.on_action("settings")
	app._process(.016)
	check(stage.time<0. and stage.weight==0. and not carousel.visible,"settings stops animation and exhaust")
	check(app.previews.all(func(old): return not old.visible),"original actors stay hidden")
	print("CREW SHOWCASE: %d checks, %d failures"%[checks,failures])
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame
	quit(1 if failures else 0)
