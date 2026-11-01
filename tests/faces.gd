extends SceneTree
const Hero = preload("res://scripts/hero.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_value: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label_value)

func mouth_stays_on_face(kid: Node3D) -> bool:
	for piece: MeshInstance3D in kid.face.pieces:
		if piece.mesh.blend_shape_mode != Mesh.BLEND_SHAPE_MODE_NORMALIZED: return false
		var base: PackedVector3Array = piece.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var shapes: Array = piece.mesh.surface_get_blend_shape_arrays(0)
		var smile: float = piece.get_blend_shape_value(0)
		var opening: float = piece.get_blend_shape_value(1)
		for i in base.size():
			var p: Vector3 = base[i]*(1.0-smile-opening)+shapes[0][Mesh.ARRAY_VERTEX][i]*smile+shapes[1][Mesh.ARRAY_VERTEX][i]*opening
			if not p.is_finite() or absf(p.x) > 0.18 or p.y < -0.09 or p.y > 0.07: return false
	return true

func run() -> void:
	for girl in [false,true]:
		var kid = Hero.new()
		root.add_child(kid)
		kid.build(girl)
		for i in 90: kid.animate(1.0/60,"run",18)
		check(kid.face.opening < 0.001,"running keeps the mouth closed")
		check(not kid.mouth.get_node("teeth").visible,"no permanent toothy grin during running")
		check(kid.face.smile < 0.4,"running uses a relaxed smile")
		check(mouth_stays_on_face(kid),"relaxed lips fit the face")
		var min_open := 1.0
		var max_open := 0.0
		var min_height := 10.0
		var max_height := -10.0
		var minimum_brow := 10.0
		var maximum_brow := -10.0
		for i in 240:
			kid.animate(1.0/60,"win")
			if i < 40: continue
			min_open = minf(min_open,kid.face.opening)
			max_open = maxf(max_open,kid.face.opening)
			min_height = minf(min_height,kid.body.position.y)
			max_height = maxf(max_height,kid.body.position.y)
			minimum_brow = minf(minimum_brow,kid.face.brows[0].position.y)
			maximum_brow = maxf(maximum_brow,kid.face.brows[0].position.y)
		check(kid.face.smile > 0.95,"victory animates a stronger smile")
		check(min_open < 0.03 and max_open > 0.4,"victory alternates short laughter and closed smiles")
		check(max_height-min_height > 0.15,"victory includes happy hops")
		check(maximum_brow-minimum_brow < 0.005,"victory avoids exaggerated raised brows")
		check(mouth_stays_on_face(kid),"celebration mouth never stretches beyond the cheeks")
		for i in 90: kid.animate(1.0/60,"idle")
		check(kid.face.opening < 0.001 and not kid.mouth.get_node("teeth").visible,"mouth closes after celebration")
		for i in 60: kid.animate(1.0/60,"jump")
		check(kid.face.smile > 0.5 and kid.face.opening < 0.001,"ordinary jump has a cheerful closed smile")
		kid.free()
	print("FACES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
