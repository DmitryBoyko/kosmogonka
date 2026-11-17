extends RefCounted

const G = preload("res://scripts/geometry.gd")
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
	["Песчаный колючник", "spine", "a27445", "ffd27c", "jump"],
	["Неоновый хлыст", "eel", "375bb5", "fa78eb", "duck"],
	["Коралловая створка", "shell", "1d8c9d", "89ffed", "jump"],
	["Солнечный веер", "fan", "a37628", "ffdd46", "duck"],
	["Споровый груздь", "fungus", "684383", "ff92b3", "duck"],
	["Инейная щетина", "spine", "307090", "acfbff", "jump"],
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

static func branch(parent: Node3D, from: Vector3, to: Vector3, thickness: float, ink: String) -> void:
	var piece := G.tube(parent, thickness, from.distance_to(to), (from + to) * .5, ink, thickness * .62)
	piece.quaternion = Quaternion(Vector3.UP, (to - from).normalized())

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
	match event.kind:
		"arc_rail":
			for i in 17:
				var z := 12. - i * 1.5
				var y := rail_height(-z)
				G.box(root, Vector3(1.98, .17, 1.35), Vector3(0., y - .10, z), "263758")
				for side: float in [-1., 1.]:
					G.box(root, Vector3(.13, .12, 1.2), Vector3(side * .93, y, z), ink, .85)
				if i % 3 == 0 and y > .25:
					G.tube(root, .17, y, Vector3(0., y * .5, z), "3a4969")
		"arc_break":
			G.box(root, Vector3(2.4, .07, 4.1), Vector3(0., .02, 0.), "191e3e")
			for side: float in [-1., 1.]:
				G.box(root, Vector3(.16, .13, 4.), Vector3(side * 1.10, .12, 0.), "ff7042", .8)
				var panel := G.box(movers, Vector3(1.04, .23, 3.8), Vector3(side * .53, .22, 0.), "6f6984")
				panel.set_meta("side", side)
		"arc_beam":
			for side: float in [-1., 1.]:
				G.box(root, Vector3(.28, 2.95, .38), Vector3(side * 1.08, 1.48, 0.), "333856")
				for y: float in [.72, 1.53, 2.34]:
					G.box(root, Vector3(.31, .06, .4), Vector3(side * 1.08, y, 0.), "ffb94d", .8)
			G.box(movers, Vector3(2.2, .13, .22), Vector3.ZERO, "ff496b", 1.35)
			G.box(movers, Vector3(2.22, .055, .26), Vector3.ZERO, "ffcfde", 1.3)
		"arc_spring":
			G.tube(root, .96, .28, Vector3(0., .14, 0.), "35476e")
			G.tube(movers, .78, .13, Vector3(0., .16, 0.), "314c6b")
			for radius: float in [.28, .49, .77]:
				G.ring(movers, radius - .08, radius, Vector3(0., .24, 0.), ink, 1.1)
		"arc_pulse":
			for i in 3:
				var z := float(1 - i) * 4.
				G.box(root, Vector3(2.22, .12, 1.32), Vector3(0., .07, z), "292b4f")
				var piston := G.box(movers, Vector3(1.68, .60, 1.05), Vector3(0., .15, z), "d64c72", .22)
				piston.set_meta("pulse_index", i)
				G.box(piston, Vector3(.48, .07, .64), Vector3(0., .33, 0.), "ffc44e", .85)
		"arc_bio":
			build_species(root, movers, data)
			root.set_meta("species", data[1])
			var low_family: bool = data[1] in ["prism", "spine", "shell"]
			root.set_meta("grown_height", (.76 if low_family else .47) if data[4] == "jump" else 1.)
	G.merge_static(root)
	return root

static func build_species(root: Node3D, movers: Node3D, data: Array) -> void:
	var stem: String = data[2]
	var tips: String = data[3]
	for side: float in [-1., 1.]:
		G.tube(root, .26, .22, Vector3(side * 1.04, .12, 0.), stem, .34)
	match data[1]:
		"vine", "eel":
			for side: float in [-1., 1.]:
				var start := Vector3(side * 1.04, .1, 0.)
				for i in 5:
					var t := float(i + 1) / 5.
					var tip := Vector3(side * (1.04 - t * .99), 2.12 * sqrt(t), sin(i * 1.7) * .24)
					branch(movers, start, tip, .17 - i * .014, stem if i < 3 else tips)
					var leaf := G.ball(movers, Vector3(.52, .13, .29), tip + Vector3(side * .12, .04, 0.), tips, .22)
					leaf.rotation.z = side * .55
					start = tip
		"fungus":
			for side: float in [-1., 1.]:
				var cap_at := Vector3(side * .52, 2.32, .18 * side)
				branch(movers, Vector3(side * .97, .12, 0.), cap_at, .20, stem)
				G.ball(movers, Vector3(1.48, .66, 1.34), cap_at, tips, .18)
				for i in 5:
					var angle := float(i) * TAU / 5.
					G.ball(movers, Vector3(.18, .08, .17), cap_at + Vector3(cos(angle) * .40, .28, sin(angle) * .31), "f9d5c0", .40)
		"shell":
			for side: float in [-1., 1.]:
				for rib in 6:
					var z := (float(rib) - 2.5) * .19
					branch(movers, Vector3(side * 1.02, .20, z * .68), Vector3(side * .23, 1.15 + (.45 if data[4] == "duck" else .0) + sin(rib * PI / 5.) * .36, z), .15, tips)
				G.ball(movers, Vector3(.95, 1.08, 1.26), Vector3(side * .65, .69, 0.), stem)
		"fan", "wing":
			branch(movers, Vector3(-1.08, .12, .18), Vector3(-.65, 2.2, 0.), .18, stem)
			branch(movers, Vector3(1.08, .12, -.18), Vector3(.65, 2.2, 0.), .18, stem)
			for i in 7:
				var angle := (float(i) - 3.) * .36
				var petal := G.ball(movers, Vector3(.52, 1.26, .22), Vector3(sin(angle) * .89, 1.81 + cos(angle) * .35, cos(i) * .18), tips if i % 2 == 0 else stem, .25)
				petal.rotation.z = -angle
		_:
			for i in 7:
				var x := (float(i) - 3.) * .32
				var peak := .78 + (1. - absf(x)) * .54
				branch(movers, Vector3(x, .14, .28 * cos(i)), Vector3(x * 1.18, peak, -.18 * sin(i)), .19, tips if i % 2 == 0 else stem)

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
