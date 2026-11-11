extends RefCounted

const G = preload("res://scripts/geometry.gd")
const Shell = preload("res://scripts/salvage_mesh.gd")

# Original palette column and row, shadow and highlight, quiff side and lift.
const STYLES := {
	"female-a": [7,3,"ad2c27","ff8441",0.,0.],
	"female-b": [1,2,"1684d0","70e2ff",0.,0.],
	"female-c": [3,3,"ca7a19","fff477",0.,0.],
	"female-d": [1,2,"95183f","ee5688",0.,0.],
	"female-e": [7,3,"8a31ba","e6a0ff",0.,0.],
	"female-f": [1,2,"1d9d91","8dffe0",0.,0.],
	"male-a": [7,3,"52352c","b98256",-1.,.087],
	"male-b": [1,2,"694230","c79868",0.,0.],
	"male-c": [1,2,"543627","ac7a54",0.,0.],
	"male-d": [1,2,"675036","c9a375",1.,.064],
	"male-e": [3,2,"5b3942","a76b7b",-1.,.093],
	"male-f": [7,3,"232736","606a86",1.,.080],
	"male-g": [3,3,"4d4039","947967",0.,0.],
	"worker": [7,3,"58433b","a4826b",0.,0.],
	"alien": [3,2,"9e355d","ff7899",0.,0.],
	"soldier": [3,2,"3a4937","81916b",0.,0.],
	"raider": [7,3,"513c44","a77583",0.,0.],
	"zombie": [7,3,"314b47","719786",-1.,.048],
}

static func strand(style: Array, model: String, uv: Vector2, point: Vector3) -> bool:
	if model == "male-g" and point.y > .46:
		return false
	if model == "female-f":
		return int(uv.y * 4.) == 2 and int(uv.x * 16.) in [1,3]
	return int(uv.x * 16.) == style[0] and int(uv.y * 4.) == style[1]

static func shape(point: Vector3, style: Array) -> Vector3:
	var lift: float = style[5]
	if lift == 0.:
		return point
	var side: float = style[4]
	var crown := smoothstep(.59,.67,point.y) * smoothstep(-.11,.12,point.z)
	var sweep := clampf(.65 + side * point.x * 3.,.22,1.)
	point.y += crown * sweep * lift
	point.x += side * .023 * crown
	point.z += .027 * crown * sweep
	return point

static func tint(style: Array, uv: Vector2, point: Vector3) -> Color:
	var strand_light := .5 + .5 * sin(point.x * 38. - point.z * 19. + point.y * 8.)
	var atlas_light := 1. - clampf((fposmod(uv.y * 4.,1.) - .10) / .82,0.,1.)
	var light := clampf(.16 + atlas_light * .58 + smoothstep(.49,.76,point.y) * .23 + strand_light * .12,0.,1.)
	return Color(style[2]).lerp(Color(style[3]),light)

static func material(style: Array) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.vertex_color_is_srgb = true
	paint.roughness = .67
	paint.emission_enabled = true
	paint.emission = Color(style[2])
	paint.emission_energy_multiplier = .17
	return paint

static func add_braids(helmet: Node3D) -> void:
	var braids := Node3D.new()
	braids.name = "CopperBraids"
	helmet.add_child(braids)
	var strand_paint := [G.material("ab3924"),G.material("d85829"),G.material("ee7937")]
	for side in [-1.,1.]:
		var tip := braid_center(side,1.)
		for strand in 3:
			var points: Array[Vector3] = []
			var radii: Array[float] = []
			for i in 13:
				var u := float(i)/12.
				var phase := u*TAU*2.8+strand*TAU/3.
				var offset := Vector3(cos(phase)*side,0.,sin(phase))*lerpf(.020,.010,u)
				points.append(braid_center(side,u)+offset)
				radii.append(lerpf(.017,.010,u))
			Shell.limb(braids,points,radii,strand_paint[strand],6)
		G.tube(braids,.024,.024,tip+Vector3.UP*.007,"e6b98b",.12)
		var end := G.ball(braids,Vector3(.040,.075,.046),tip-Vector3.UP*.041,"b94526")
		end.rotation.z = side*.21
	G.merge_static(braids)

static func braid_center(side: float, u: float) -> Vector3:
	return Vector3(side*(.163+sin(u*PI)*.051-u*.007),lerpf(.161,-.103,u),lerpf(.030,.108,u)+sin(u*PI)*.017)
