extends RefCounted

const G = preload("res://scripts/geometry.gd")
const Cargo = preload("res://scripts/cargo_containers.gd")
const MeshTools = preload("res://scripts/salvage_mesh.gd")
const Metals = preload("res://scripts/salvage_materials.gd")
const Plants = preload("res://scripts/plant_kit.gd")
const Planets = preload("res://scripts/planets.gd")
const TECH = ["arc_rail", "arc_break", "arc_beam", "arc_spring", "arc_pulse"]
const TITLES = {
	"arc_rail": "МАГНИТНЫЙ РЕЛЬС", "arc_break": "НЕПРОЧНЫЙ НАСТИЛ",
	"arc_beam": "ФАЗОВЫЙ ЛАЗЕР", "arc_spring": "ГРАВИПРУЖИНА",
	"arc_pulse": "ИМПУЛЬСНАЯ ГРЕБЁНКА",
}
const ACTIONS = {
	"arc_rail": "ДЕРЖИ ПОЛОСУ · ВЕРХНИЕ ЗВЁЗДЫ", "arc_break": "ЯНТАРНАЯ КРОМКА · ПРЫЖОК",
	"arc_beam": "ЛУЧ ПОДНИМАЕТСЯ · ПОДКАТ", "arc_spring": "ВСТАНЬ НА ПРУЖИНУ · ВЗЛЁТ",
	"arc_pulse": "ТРИ УДАРА · ПРЫЖОК ИЛИ ОБХОД",
}
const BIO = [
	["Кристаллолист", "prism", "45cda4", "c4a6ff", "jump"],
	["Лиана-хват", "vine", "267853", "f88ea8", "duck"],
	["Дюнная розетка", "spine", "a27445", "ffd27c", "jump"],
	["Неоновый хлыст", "eel", "375bb5", "fa78eb", "duck"],
	["Коралловая створка", "shell", "1d8c9d", "89ffed", "jump"],
	["Солнечный веер", "fan", "a37628", "ffdd46", "duck"],
	["Споровый груздь", "fungus", "684383", "ff92b3", "duck"],
	["Снежный папоротник", "spine", "307090", "acfbff", "jump"],
	["Жароцвет", "fan", "912b36", "ffac38", "jump"],
	["Сумеречный мотылёк", "wing", "62368a", "dc53de", "duck"],
	["Зеркальный полип", "shell", "578bae", "aefcf4", "jump"],
	["Парусный папоротник", "wing", "327471", "7ffff0", "duck"],
	["Гриб-фонарь", "fungus", "493965", "e28bff", "jump"],
	["Приливный анемон", "eel", "247896", "67ffee", "duck"],
	["Громовой корнеузел", "vine", "8f4d39", "ffdf81", "jump"],
	["Доковая щёлкушка", "shell", "315d76", "8affdd", "duck"],
	["Сумеречная орхидея", "fan", "792f71", "ffd2fa", "duck"],
	["Микорная колокольня", "fungus", "725096", "bcff95", "duck"],
	["Лагунный коралловик", "prism", "1e778d", "6befff", "jump"],
	["Аэронов парусник", "wing", "3d8493", "9cf4d4", "jump"],
]

static func species(world: int) -> Array:
	return BIO[world] if world < BIO.size() else BIO[Planets.style_index(world)]

static func rail_height(rel: float) -> float:
	return 2.4 * (smoothstep(-12., -5., rel) - smoothstep(4., 12., rel))

static func pulse(rel: float, index: int) -> float:
	var center := float(index - 1) * 4.0
	return smoothstep(center - 3.4, center - .85, rel) * (1. - smoothstep(center + 1.1, center + 3.4, rel))

static func beam_height(rel: float) -> float:
	return lerpf(.65, 2.30, smoothstep(-17., -4., rel))

static func shutter(rel: float) -> float:
	return smoothstep(-19., -8., rel)

static func build(event: Dictionary, world: int) -> Node3D:
	var root := Node3D.new()
	var movers := Node3D.new()
	movers.set_meta("motion", true)
	root.add_child(movers)
	root.set_meta("moving_parts", movers)
	var data := species(world)
	var ink: String = data[3] if event.kind == "arc_bio" else Planets.get_data(world).accent
	var name_value: String = data[0] if event.kind == "arc_bio" else TITLES[event.kind]
	var sign := G.label(root, name_value.to_upper(), Vector3(0., 3.8, .8), 21)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = .007
	sign.modulate = Color(ink).lerp(Color.WHITE, .46)
	var instruction: String = ("ПОДКАТ ИЛИ ОБХОД" if data[4] == "duck" else "ПРЫЖОК ИЛИ ОБХОД") if event.kind == "arc_bio" else ACTIONS[event.kind]
	var cue := G.label(root, instruction, Vector3(0., 3.5, .8), 16)
	cue.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cue.pixel_size = .006
	cue.modulate = Color("fff0b1")
	var shell := Metals.material("hull-titanium",true)
	var moving_metal := Metals.material("hull-salvage")
	var axle := Metals.material("hull-titanium")
	match event.kind:
		"arc_rail":
			for i in 17:
				var z := 12. - i * 1.5
				var y := rail_height(-z)
				MeshTools.block(root,Vector3(1.98,.17,1.35),Vector3(0,y-.10,z),shell)
				for side: float in [-1., 1.]:
					G.box(root, Vector3(.13, .12, 1.2), Vector3(side * .93, y, z), ink, .85)
				if i % 3 == 0 and y > .25:
					for side in [-1.,1.]:
						MeshTools._beam(root,Vector3(0,0,z),Vector3(side*.82,y-.1,z),.085,axle)
		"arc_break":
			MeshTools.block(root,Vector3(2.4,.07,4.1),Vector3(0,.02,0),shell)
			for side: float in [-1., 1.]:
				G.box(root, Vector3(.16, .13, 4.), Vector3(side * 1.10, .12, 0.), "ff7042", .8)
				MeshTools._beam(root,Vector3(side*1.07,.13,-1.85),Vector3(side*1.07,.13,1.85),.098,axle)
				var panel := MeshTools.block(movers,Vector3(1.04,.23,3.8),Vector3(side*.53,.22,0),moving_metal)
				panel.set_meta("side", side)
		"arc_beam":
			for side: float in [-1., 1.]:
				var generator := Cargo.fitted(14 if world%2==0 else 17,Vector3(.54,.64,.85))
				root.add_child(generator)
				generator.position=Vector3(side*1.2,0,0)
				MeshTools.block(root,Vector3(.27,2.95,.38),Vector3(side*1.19,1.48,0),shell)
				MeshTools._beam(root,Vector3(side*1.07,.25,0),Vector3(side*1.07,2.75,0),.061,axle)
				for y: float in [.72,1.53,2.34]:
					G.box(root,Vector3(.25,.042,.32),Vector3(side*1.25,y,.075),ink,.67)
				MeshTools.block(movers,Vector3(.28,.28,.38),Vector3(side*1.07,0,0),moving_metal)
			G.box(movers, Vector3(2.2, .13, .22), Vector3.ZERO, "ff496b", 1.35)
			G.box(movers, Vector3(2.22, .055, .26), Vector3.ZERO, "ffcfde", 1.3)
		"arc_spring":
			MeshTools.block(root,Vector3(1.94,.24,1.77),Vector3(0,.12,0),shell,.18)
			MeshTools._cylinder(movers,.77,.13,Vector3(0,.16,0),moving_metal)
			for side in [-1.,1.]:
				MeshTools._beam(root,Vector3(side*.67,.08,.55),Vector3(side*.67,.37,-.57),.08,axle)
			for radius: float in [.28, .49, .77]:
				G.ring(movers, radius - .08, radius, Vector3(0., .24, 0.), ink, 1.1)
		"arc_pulse":
			for i in 3:
				var z := float(1 - i) * 4.
				MeshTools.block(root,Vector3(2.22,.14,1.32),Vector3(0,.07,z),shell)
				for side in [-1.,1.]:
					MeshTools.block(root,Vector3(.19,.28,1.29),Vector3(side*.99,.13,z),axle)
					G.box(root,Vector3(.09,.03,.82),Vector3(side*.99,.285,z),ink,.55)
				var piston := MeshTools.block(movers,Vector3(1.68,.60,1.05),Vector3(0,.15,z),moving_metal)
				piston.set_meta("pulse_index", i)
				G.box(piston, Vector3(.48, .07, .64), Vector3(0., .33, 0.), "ffc44e", .85)
		"arc_bio":
			build_species(root,movers,data,world)
			root.set_meta("species",data[1])
			root.set_meta("grown_height",1.)
	G.merge_static(root)
	return root

static func growth(root: Node3D, world: int, species_key: String, size: Vector3, point: Vector3, angle: float) -> void:
	var bounds: AABB = Plants.prototype(species_key).bounds
	var basis := Basis(Vector3.UP,angle)*Basis.from_scale(size/bounds.size.max(Vector3.ONE*.01))
	var placements: Array[Transform3D] = [Transform3D(basis,point)]
	Plants.batch(root,world,species_key,placements,true,155.)

static func build_species(root: Node3D, movers: Node3D, data: Array, world: int) -> void:
	var forms := {"prism":"crystals","vine":"hanging_ivy","spine":"fork_cactus","eel":"alien_leaf",
		"shell":"lettuce_coral","fan":"broad_fronds","fungus":"amanita","wing":"fern"}
	var kind: String = data[1]
	var style := Planets.style_index(world)
	var model: String = forms[kind]
	if kind=="spine" and style==7: model="snow_pine"
	if kind=="shell" and style!=4: model="broad_fronds"
	if kind=="prism" and style==4: model="staghorn_coral"
	if kind=="vine" and style==8: model="deadwood"
	if data[4]=="duck":
		for side in [-1.,1.]:
			growth(root,world,model,Vector3(.35,2.05,1.14),Vector3(side*1.04,0.,0.),side*.15)
			growth(movers,world,model,Vector3(1.21,1.14,1.31),Vector3(side*.49,1.51,0.),side*.23)
	else:
		growth(movers,world,model,Vector3(1.68,1.28,1.18),Vector3(0.,0.,.07),.23)
		for side in [-1.,1.]:
			growth(root,world,model,Vector3(.61,.53,.63),Vector3(side*.71,0.,-.33),side*.37)

static func present(node: Node3D, event: Dictionary, rel: float) -> void:
	var part: Node3D = node.get_meta("moving_parts")
	match event.kind:
		"arc_break":
			for panel: Node3D in part.get_children():
				panel.rotation.z = -float(panel.get_meta("side")) * shutter(rel) * 1.28
				panel.position.y = .22 - shutter(rel) * .94
		"arc_beam":
			part.position.y = beam_height(rel)
		"arc_spring":
			part.position.y = .10 + .10 * smoothstep(-12., -2., rel)
		"arc_pulse":
			for piston: Node3D in part.get_children():
				piston.position.y = .12 + pulse(rel, int(piston.get_meta("pulse_index"))) * .71
		"arc_bio":
			var growth := smoothstep(-22., -4., rel)
			var grown_height: float = node.get_meta("grown_height")
			part.scale.y = grown_height
			match String(node.get_meta("species")):
				"vine", "eel":
					part.scale.y = grown_height * lerpf(.66, 1., growth)
					part.rotation.y = lerpf(.95, 0., growth)
				"shell":
					part.scale = Vector3(lerpf(.55, 1., growth), grown_height * lerpf(.45, 1., growth), 1.)
				"fungus":
					part.scale = Vector3(lerpf(.53, 1., growth), grown_height * lerpf(.87, 1., growth), lerpf(.75, 1., growth))
				"fan", "wing":
					part.rotation.x = lerpf(1.14, 0., growth)
				_:
					part.scale.y = grown_height * lerpf(.28, 1., growth)
