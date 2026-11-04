extends MultiMeshInstance3D
const G=preload("res://scripts/geometry.gd")
var width:=-1.
func build(planet:int) -> void:
	name="Crossing"
	var stripe:=BoxMesh.new(); stripe.size=Vector3(.37,.018,2.2)
	multimesh=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.mesh=stripe; multimesh.instance_count=13
	material_override=G.material(["ffd060","ff72dc","63ffe0","daff66"][preload("res://scripts/planets.gd").biome(planet)],.65)
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; configure(7.8)
func configure(road_width:float) -> void:
	if is_equal_approx(width,road_width): return
	width=road_width
	var count:int=clampi(floori(width/.63),3,13)
	multimesh.visible_instance_count=count
	for i in count: multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3((i-(count-1)*.5)*.63,.065,0)))
