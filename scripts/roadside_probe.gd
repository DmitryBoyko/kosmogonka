extends Node3D

const MODEL := preload("res://assets/scout_probe/eye-drone.glb")
const SCAN := preload("res://assets/scout_probe/scan.gdshader")
const Course := preload("res://scripts/course.gd")
const LOOP_SPAN := preload("res://scripts/loop_routes.gd").SPAN
const FLIGHT_LENGTH := 112.
const HEADROOM := 26.

var rng := RandomNumberGenerator.new()
var exclusions: Array[Vector2] = []
var encounters: Array[Vector2] = []
var craft: Node3D
var beam: MeshInstance3D
var field: ShaderMaterial

func _ready() -> void:
	hide()

func configure(world: int, layout_seed: int, events: Array, routes: Array) -> void:
	hide()
	rng.seed = layout_seed ^ (14369+world*937)
	exclusions.assign([Vector2(Course.FRONT_START-18.,Course.FRONT_END+Course.TRANSITION+18.)])
	for event: Dictionary in events:
		if event.kind in ["basement","tunnel","passage","upper_stairs","stairs"]:
			var extent: float = float(event.length)*.5+HEADROOM
			exclusions.append(Vector2(event.s-extent,event.s+extent))
	for route: Dictionary in routes:
		exclusions.append(Vector2(route.start-HEADROOM,route.start+LOOP_SPAN+HEADROOM))
	encounters.clear()
	var finish := Course.length_for(world)-130.
	var start := rng.randf_range(165.,305.)
	while start+FLIGHT_LENGTH<finish:
		var next_start := start
		for span in exclusions:
			if start<span.y and start+FLIGHT_LENGTH>span.x:
				next_start = maxf(next_start,span.y)
		if next_start>start:
			start = next_start+rng.randf_range(0.,8.)
			continue
		encounters.append(Vector2(start,-1. if rng.randf()<.5 else 1.))
		start += FLIGHT_LENGTH+rng.randf_range(450.,830.)

func create_visual() -> void:
	craft = MODEL.instantiate()
	craft.name = "EyeDrone"
	craft.scale = Vector3.ONE*1.5
	add_child(craft)
	for mesh: MeshInstance3D in craft.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cone := CylinderMesh.new()
	cone.top_radius = .08
	cone.bottom_radius = .95
	cone.height = 1.
	cone.radial_segments = 18
	cone.rings = 0
	cone.cap_top = false
	cone.cap_bottom = false
	field = ShaderMaterial.new()
	field.shader = SCAN
	beam = MeshInstance3D.new()
	beam.name = "ScanField"
	beam.mesh = cone
	beam.material_override = field
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)

func present(distance: float, target: Vector3, track: RefCounted, eligible: bool, reduced_motion: bool) -> void:
	hide()
	if not eligible: return
	for encounter in encounters:
		var offset := distance-encounter.x
		if offset<0. or offset>=FLIGHT_LENGTH: continue
		if not is_instance_valid(craft): create_visual()
		var progress := offset/FLIGHT_LENGTH
		var crossing := smoothstep(.37,.65,progress)
		var side := encounter.y*lerpf(1.,-1.,crossing)
		var approach := smoothstep(0.,.28,progress)
		var depart := smoothstep(.77,1.,progress)
		var sway := 0. if reduced_motion else sin(progress*TAU*2.)*.28
		craft.position = track.map(Vector3(side*(4.8+(1.-approach)*3.+depart*4.),4.4+maxf(0.,target.y-1.3)+sway+depart*3.,-lerpf(26.,8.,approach)-depart*27.))
		var delta := target-craft.position
		craft.rotation = Vector3(-.12,atan2(delta.x,delta.z),side*.13)
		beam.visible = progress>.24 and progress<.82
		if beam.visible:
			beam.position = craft.position+delta*.5
			beam.quaternion = Quaternion(Vector3.DOWN,delta.normalized())
			beam.scale = Vector3(1.,delta.length(),1.)
			field.set_shader_parameter("scan_phase",.5 if reduced_motion else fposmod(progress*6.,1.))
			field.set_shader_parameter("strength",smoothstep(.24,.38,progress)*(1.-smoothstep(.70,.82,progress)))
		show()
		return
