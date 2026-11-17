extends RefCounted

const G = preload("res://scripts/geometry.gd")
const Cargo = preload("res://scripts/cargo_containers.gd")
const MeshTools = preload("res://scripts/salvage_mesh.gd")
const Metals = preload("res://scripts/salvage_materials.gd")
const Planets = preload("res://scripts/planets.gd")
const Route = preload("res://scripts/expedition_course.gd")
const Worlds = preload("res://scripts/expedition_worlds.gd")
const Rock = preload("res://scripts/rock_terrain.gd")
const Platforms = preload("res://scripts/flying_platforms.gd")
const STEEL := "26354d"
const WIND := "72efcf"
const PULSE := "deabff"
const AMBER := "ffbc56"

static func build(piece: Dictionary, planet: int) -> Node3D:
	var root := Node3D.new()
	match piece.kind:
		"exp_gate": gate(root,piece,planet)
		"exp_lift": lift(root,planet)
		"exp_deck": deck(root,piece,planet)
		"exp_ufo": ufo(root,planet)
	G.merge_static(root)
	# These nodes move independently of the baked structure.
	if piece.kind == "exp_gate":
		var action: String = piece.action
		var height: float = 3.05 if action == "avoid" else 2.55
		var lights := Node3D.new()
		lights.name = "Countdown"
		root.add_child(lights)
		for i in 3:
			G.box(lights, Vector3(.27, .15, .08), Vector3((i - 1) * .39, height + .43, 1.03), STEEL)
		if action != "jump":
			shutter_panel(root,piece,planet)
	elif piece.kind == "exp_lift":
		var stream := Node3D.new()
		stream.name = "Airflow"
		root.add_child(stream)
		for i in 3:
			var ring := G.ring(stream, .74, .81, Vector3(0, 1.1 + i * .69, -.7 - i), WIND, .55)
			ring.rotation.x = PI / 2.
	return root

static func ufo(root: Node3D, planet: int) -> void:
	var tint: String = preload("res://scripts/planets.gd").get_data(planet).accent
	var craft := Node3D.new()
	craft.name="Saucer"
	craft.set_meta("motion",true)
	root.add_child(craft)
	G.ball(craft,Vector3(2.30,.73,2.30),Vector3(0.,.72,0.),"5066db")
	G.ball(craft,Vector3(2.36,.13,2.36),Vector3(0.,.77,0.),"8eefff",.28)
	G.ball(craft,Vector3(1.60,.31,1.60),Vector3(0.,1.04,0.),"4852a2")
	var glass := StandardMaterial3D.new()
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color=Color(.30,.78,1.,.18)
	glass.roughness=.24
	var dome := G.ball(craft,Vector3(1.45,1.44,1.43),Vector3(0.,1.61,0.))
	dome.material_override=glass
	dome.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pilot := preload("res://scripts/crew_avatar.gd").new()
	pilot.name="Pilot"
	craft.add_child(pilot)
	pilot.build(preload("res://scripts/crew.gd").ALIEN_GUY)
	pilot.pose("pilot")
	pilot.scale=Vector3.ONE*.43
	pilot.position=Vector3(0.,.78,.10)
	pilot.set_meta("motion",true)
	for mesh: GeometryInstance3D in pilot.find_children("*","GeometryInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 8:
		var a := TAU*float(i)/8.
		G.ball(craft,Vector3.ONE*.15,Vector3(cos(a),.72,sin(a))*Vector3(1.10,1.,1.10),
			tint if i%2==0 else AMBER,.45)
	preload("res://scripts/arcade_materials.gd").apply(craft,planet)
	pilot.set_meta("motion",true)
	G.merge_static(craft)
	root.set_meta("saucer",craft)
	root.set_meta("pilot",pilot)

static func freight(root: Node3D, variant: int, size: Vector3, foot: Vector3) -> void:
	var box := Cargo.fitted(variant,size)
	root.add_child(box)
	box.position = foot

static func cargo_variant(piece: Dictionary, planet: int) -> int:
	var warm := [1,3,6,14,2,4,11,12,7,10,15]
	var cool := [0,8,1,17,6,16,9,5,15,14,2]
	var style := Planets.style_index(planet)
	return warm[style] if piece.get("shape",0)==0 else cool[style]

static func gate(root: Node3D, piece: Dictionary, planet: int) -> void:
	var action: String = piece.action
	var accent: String = Planets.get_data(planet).accent
	var span: float = piece.length
	var variant := cargo_variant(piece,planet)
	var frame := Metals.material("hull-titanium",true)
	var guide := Metals.material("hull-titanium")
	var limiter := Metals.glow(Color(accent))
	var caution := Metals.glow(Color(AMBER))
	for side in [-1.,1.]:
		MeshTools.block(root,Vector3(.35,.14,span+.48),Vector3(side*.97,.07,0),frame)
		MeshTools.block(root,Vector3(.11,.045,span+.42),Vector3(side*.98,.142,0),limiter)
	if action == "jump":
		freight(root,variant,Vector3(1.60,.68,span*.90),Vector3(0,.16,0))
		MeshTools.block(root,Vector3(1.94,.15,span),Vector3(0,.86,0),frame)
		for x in [-.73,0.,.73]:
			MeshTools.block(root,Vector3(.22,.09,.045),Vector3(x,.85,span*.5),caution)
	else:
		var top := 2.55 if action=="duck" else 3.65
		for side in [-1.,1.]:
			freight(root,variant,Vector3(.51,1.01,minf(span,.94)),Vector3(side*1.26,0,.08))
			MeshTools.block(root,Vector3(.29,top,.52),Vector3(side*1.27,top*.5,0),frame)
			MeshTools._beam(root,Vector3(side*1.07,.28,.16),Vector3(side*1.07,top+.08,.16),.055,guide)
			MeshTools.block(root,Vector3(.34,.29,.57),Vector3(side*1.24,top-.22,0),limiter)
		freight(root,variant,Vector3(2.72,.48,minf(span,1.01)),Vector3(0,top-.10,0))
	if piece.bonus:
		var sign := G.label(root, "★", Vector3(0, 3.25 if action != "avoid" else 4.1, span*.5+.15), 48)
		sign.modulate = Color(accent)
		sign.pixel_size = .023
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED

static func shutter_panel(root: Node3D, piece: Dictionary, planet: int) -> void:
	var panel := Node3D.new()
	panel.name = "ShutterPanel"
	panel.set_meta("motion",true)
	root.add_child(panel)
	var top := 2.54 if piece.action=="duck" else 3.65
	var bottom := 1.48 if piece.action=="duck" else .07
	var depth := minf(float(piece.length),.92)
	panel.position.y=top
	var step := (top-bottom)/(2. if piece.action=="duck" else 5.)
	var metal := Metals.material("hull-salvage")
	var edge := Metals.glow(Color(Planets.get_data(planet).accent))
	var slat_count := 2 if piece.action=="duck" else 5
	for i in slat_count:
		var slat := Node3D.new()
		panel.add_child(slat)
		slat.position.y = -(i+.5)*step
		slat.set_meta("closed_y",slat.position.y)
		MeshTools.block(slat,Vector3(2.11,step*.89,depth),Vector3.ZERO,metal)
		MeshTools.block(slat,Vector3(1.76,.027,.036),Vector3(0,-step*.41,depth*.5+.02),edge)
		if i==slat_count-1:
			MeshTools.block(slat,Vector3(2.16,.075,depth+.06),Vector3(0,-step*.5+.05,0),Metals.glow(Color(AMBER)))
		G.merge_static(slat)
static func lift(root: Node3D, planet: int) -> void:
	var launcher := Node3D.new()
	root.add_child(launcher)
	launcher.position=Vector3(0,.10,.90)
	launcher.scale=Vector3(.86,.45,1.)
	Platforms.build_module(launcher,4.6,posmod(planet+3,Platforms.STYLES.size()))
	for side in [-1.,1.]:
		G.box(root, Vector3(.13,.075,4.5), Vector3(side*.92,.13,.9), WIND, .75)
		G.tube(root, .12, 2.75, Vector3(side * .99, 1.39, .10), STEEL)
		for i in 3:
			var ribbon := G.box(root, Vector3(.5,.045,.30), Vector3(side * 1.11, 2.6 - i * .27, .10), WIND, .45)
			ribbon.rotation.z = side * (.19 + i * .15)
	for i in 4:
		G.box(root, Vector3(1.32,.045,.09), Vector3(0,.14,2.6-i*.95), WIND, .65)
	var sign := G.label(root, "★", Vector3(0, 3.5, 1.5), 52)
	sign.pixel_size = .026
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color(WIND)

static func deck(root: Node3D, piece: Dictionary, planet: int) -> void:
	var slope := atan2(float(piece.to_y) - float(piece.from_y), float(piece.length))
	var span := Node3D.new()
	root.add_child(span)
	span.position.y = Route.deck_height(piece, 0.)
	span.rotation.x = slope
	var length: float = piece.length / cos(slope)
	Platforms.build_chain(span,length,0.,planet+roundi(piece.s/40.),.80)
	for i in range(2, int(length), 4):
		G.box(span, Vector3(2.09,.026,.11), Vector3(0,.016,length*.5-i), "73adc0", .2)
	if piece.get("jump_edge", false) or piece.get("landing_edge", false):
		var edge: float = -length*.5+.16 if piece.get("jump_edge", false) else length*.5-.16
		G.box(span, Vector3(2.2,.08,.28), Vector3(0,.04,edge), AMBER, .76)

static func present(root: Node3D, piece: Dictionary, ahead: float, reduced: bool, time: float=0.) -> void:
	if piece.kind=="exp_ufo":
		var craft: Node3D = root.get_meta("saucer")
		var pilot: Node3D = root.get_meta("pilot")
		craft.position.y=0. if reduced else sin(time*2.4+piece.origin)*.14
		craft.rotation.z=0. if reduced else sin(time*1.7+piece.origin)*.08
		pilot.rotation.y=0. if reduced else sin(time*.8+piece.origin)*.12
	elif piece.kind == "exp_lift":
		var stream := root.get_node("Airflow") as Node3D
		stream.position.y = 0. if reduced else sin(ahead * .33) * .17
	elif piece.kind == "exp_gate":
		var progress := clampf(1. - ahead / float(piece.lead), 0., 1.)
		var lights := root.get_node("Countdown")
		var phase := 0 if ahead>piece.lead else mini(3,1+floori(progress*3.))
		if phase!=int(lights.get_meta("phase",-1)):
			lights.set_meta("phase",phase)
			for i in 3:
				var light := lights.get_child(i) as MeshInstance3D
				light.material_override = G.material(AMBER, .9) if i<phase else G.material(STEEL)
		var shutter := root.get_node_or_null("ShutterPanel") as Node3D
		if shutter and not piece.wind and not reduced:
			# The panel locks before the contact region and opens behind the runner.
			var lift := maxf(smoothstep(12., 44., ahead), smoothstep(3., 18., -ahead))
			for rail: Node3D in shutter.get_children():
				var closed: float = rail.get_meta("closed_y")
				rail.position.y = lerpf(closed,-.08,lift)
				rail.position.z = rail.get_index()*.055*lift

static func islands(root: Node3D, planet: int, index: int, seed_value: int) -> void:
	if index < 1 or posmod(index, 4) != 1:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ (index * 44839 + 47)
	for side in [-1., 1.]:
		var at := Vector3(side * rng.randf_range(42., 64.), rng.randf_range(12., 25.), -15.)
		var width := rng.randf_range(12., 21.)
		var island := G.part(root,Rock.mesh("valley" if side<0. else "rounded-range"),at,Rock.coating(planet))
		island.scale=Vector3(width, rng.randf_range(5.8,9.), width*.73)
		island.rotation.y=rng.randf()*TAU
		island.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 3:
			var shard := G.part(root,Rock.mesh("boulder"),at+Vector3((i-1)*width*.22,-.8-i*.65,0.),Rock.coating(planet))
			shard.scale=Vector3(width*.30,2.8+i*.6,width*.24)
			shard.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			shard.rotation.y=i*1.29

static func landmark(planet: int) -> Node3D:
	var root := Node3D.new()
	var style := Worlds.describe(planet)
	root.name = "ExpeditionLandmark"
	var accent: String = style.accent
	if style.route == "wind":
		G.tube(root, 1.1, 14., Vector3(0,7,0), STEEL, .42)
		G.tube(root, 1.55, .45, Vector3(0,12.55,0), STEEL)
		var hub := G.ring(root,.87,1.06,Vector3(0,14.,0),accent,.7)
		hub.rotation.x = PI / 2.
		for i in 3:
			var vane := Node3D.new()
			vane.position.y = 14.
			vane.rotation.z = i * TAU / 3.
			root.add_child(vane)
			G.box(vane, Vector3(.52,4.1,.28), Vector3(.14,2.05,0), accent, .45)
	else:
		for side in [-1., 0., 1.]:
			var y: float = 9. - absf(side) * 3.
			var x: float = side * 5.4
			G.tube(root, .88, y, Vector3(x,y*.5,0), STEEL, .54)
			G.ball(root, Vector3(6.8,2.1,5.9), Vector3(x,y,0),"723f98",.18)
			G.ring(root,2.5,2.65,Vector3(x,y-.07,0),accent,.69)
	preload("res://scripts/arcade_materials.gd").apply(root,planet)
	G.merge_static(root)
	var title := G.label(root, style.regions[2], Vector3(0, 4., 3.), 38)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return root
