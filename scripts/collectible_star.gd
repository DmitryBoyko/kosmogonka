extends RefCounted
const SM=preload("res://scripts/salvage_mesh.gd")
const G=preload("res://scripts/geometry.gd")
const LootFlash = preload("res://assets/effects/star_loot/loot_flash.gdshader")
static var mesh:ArrayMesh
static var paints: Dictionary = {}
static var glint_materials: Dictionary = {}
static var glint_quad: QuadMesh

static func value_color(amount: int) -> Color:
	if amount <= 1: return Color("48ff62")
	if amount == 2: return Color("b9ff32")
	if amount == 3: return Color("ffe433")
	if amount == 4: return Color("ff8b35")
	if amount < 10: return Color("ff247d")
	return Color("ff38c0")

static func paint(amount: int) -> ShaderMaterial:
	var color := value_color(amount)
	if not paints.has(color):
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/surfaces/arcade_gold.gdshader")
		material.set_shader_parameter("star_color", color)
		paints[color] = material
	return paints[color]
static func prepare() -> void:
	if mesh: return
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var a:=PI*.5+i*TAU/10; var b:=PI*.5+(i+1)*TAU/10
		var p:=Vector2(cos(a),sin(a))*(1.0 if i%2==0 else .47)
		var q:=Vector2(cos(b),sin(b))*(1.0 if (i+1)%2==0 else .47)
		for side in [-1.,1.]:
			var outer_p:=Vector3(p.x,p.y,side*.18); var outer_q:=Vector3(q.x,q.y,side*.18)
			var inner_p:=Vector3(p.x*.88,p.y*.88,side*.28); var inner_q:=Vector3(q.x*.88,q.y*.88,side*.28)
			if side>0:
				SM._triangle(st,Vector3(0,0,.28),inner_q,inner_p)
				SM._triangle(st,inner_p,inner_q,outer_q); SM._triangle(st,inner_p,outer_q,outer_p)
			else:
				SM._triangle(st,Vector3(0,0,-.28),inner_p,inner_q)
				SM._triangle(st,inner_q,inner_p,outer_p); SM._triangle(st,inner_q,outer_p,outer_q)
		# Godot front faces are clockwise: the old side strip faced inward and vanished.
		SM._triangle(st,Vector3(p.x,p.y,-.18),Vector3(q.x,q.y,.18),Vector3(q.x,q.y,-.18))
		SM._triangle(st,Vector3(p.x,p.y,-.18),Vector3(p.x,p.y,.18),Vector3(q.x,q.y,.18))
	mesh=st.commit()

static func build(parent:Node3D, amount:int, mega:bool=false) -> Node3D:
	prepare()
	var root:=Node3D.new(); parent.add_child(root); root.name="StarPickup"
	var spin:=Node3D.new(); root.add_child(spin); spin.name="Spin"
	var radius := .84 if mega else .40 + .085 * float(clampi(amount, 1, 5) - 1)
	var figure:=G.part(spin,mesh,Vector3.ZERO,paint(amount))
	figure.scale=Vector3.ONE*radius
	# Rotating magical pickups must not flash narrow, aliased shadows on the road.
	figure.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("radius",radius); root.set_meta("amount",amount)
	if glint_quad == null:
		glint_quad = QuadMesh.new()
		glint_quad.size = Vector2.ONE
	var tint := value_color(amount)
	if not glint_materials.has(tint):
		var material := ShaderMaterial.new()
		material.shader = LootFlash
		material.set_shader_parameter("shape", 1)
		material.set_shader_parameter("color", tint)
		material.set_shader_parameter("energy", 1.4)
		material.set_shader_parameter("alpha", .68)
		glint_materials[tint] = material
	var glint := G.part(root, glint_quad, Vector3(radius * .53, radius * .52, .15), glint_materials[tint])
	glint.name = "Glint"
	glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glint.scale = Vector3.ONE * radius
	return root

static func animate(root:Node3D, clock:float, offset:float, reduced:bool) -> void:
	var spin := root.get_node("Spin") as Node3D
	spin.rotation=Vector3(.12,clock*1.8+offset,.08)
	spin.position.y=0 if reduced else sin(clock*2.8+offset)*.075
	var glint := root.get_node("Glint") as Node3D
	var pulse := .75 if reduced else .65 + .48 * pow(.5 + .5 * sin(clock * 4.2 + offset), 3.)
	glint.scale = Vector3.ONE * float(root.get_meta("radius")) * pulse
