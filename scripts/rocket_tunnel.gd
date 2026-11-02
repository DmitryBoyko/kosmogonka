extends RefCounted
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const Jet=preload("res://scripts/jetpack_fx.gd")
const G=preload("res://scripts/geometry.gd")
const FLOOR:=3.35
const LENGTH:=44.0

static func build(variant: int=0) -> Node3D:
	var root:=Node3D.new(); root.name="RocketSkyTunnel"
	var body:=Node3D.new(); body.name="Shell"; root.add_child(body)
	var hull:=Mat.material("hull-salvage").duplicate() as ShaderMaterial
	var inner:=Mat.material("hull-titanium",true).duplicate() as ShaderMaterial
	var trim:=Mat.material("hull-titanium").duplicate() as ShaderMaterial
	for mat in [hull,inner,trim]: mat.shader=preload("res://assets/salvage/tunnel_surface.gdshader")
	shell(body,[Vector3(-22,1.28,1.95),Vector3(-13,1.28,1.95),Vector3(0,1.28,1.95),Vector3(13,1.28,1.95),Vector3(22,1.28,1.95)],5.15,hull,inner,variant)
	SM.block(body,Vector3(1.0,0.14,44),Vector3(0,FLOOR-0.07,0),trim,0.04)
	for z in [-22,-16,-8,0,8,16,22]:
		var points:Array=[]; var widths:Array=[]
		for i in 33:
			var a:=TAU*i/32.0
			points.append(Vector3(cos(a)*1.19,5.15+sin(a)*1.84,z)); widths.append(0.045)
		SM.limb(body,points,widths,trim,6)
	for side in [-1,1]:
		SM.block(body,Vector3(0.025,0.045,43.5),Vector3(side*0.38,FLOOR+0.02,0),Mat.glow(Color("a1f5e1")),0.01)
		for z in [-12,12]:
			SM.limb(body,[Vector3(side*1.13,4.35,z),Vector3(side*1.52,3.7,z),Vector3(side*1.52,3.2,z)],[0.09,0.09,0.12],trim,8)
			SM._cylinder(body,0.3,0.55,Vector3(side*1.52,3.2,z),inner,0.2)
			SM._cylinder(body,0.32,0.12,Vector3(side*1.52,2.97,z),trim,0.3)
	for z in [-20,-8,8,20]:
		var guide: Array=[]; var radii: Array=[]
		for i in 33:
			var a:=TAU*i/32.0
			guide.append(Vector3(cos(a)*1.15,5.15+sin(a)*1.77,z)); radii.append(0.018)
		SM.limb(body,guide,radii,Mat.glow(Color("578b94")),6)
	# Attached torn panels and repaired brackets keep the silhouette a rocket wreck.
	for side in [-1,1]:
		for z in [-17,7]:
			var patch:=SM.block(body,Vector3(0.09,0.6,2.0),Vector3(side*1.26,4.85,z),trim,0.04)
			patch.rotation.z=side*0.12
	SM.batch(body)
	for z in [-12,12]:
		var fx:=Jet.new(); root.add_child(fx); fx.build(); fx.position=Vector3(0,2.43,z); fx.scale=Vector3.ONE*0.7
		for i in 2: fx.jets[i].position.x=(-1 if i==0 else 1)*2.17
		fx.advance(0.2,true)
	var sign:=G.label(root,"↑↑  МЕГА ×2",Vector3(0,7.6,22.3),29); sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate=Color("ffe8a1")
	root.set_meta("tunnel_floor",FLOOR)
	return root

static func advance(root: Node3D, dt: float) -> void:
	for child in root.get_children():
		if child is Jet: child.advance(dt,true)

static func shell(root: Node3D,sections: Array,center_y: float,outer: Material,inner: Material,seed_value: int) -> void:
	var tools: Array[SurfaceTool] = []
	for _i in 2:
		var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES); tools.append(tool)
	var rings: Array = []; var inside: Array = []
	for row in sections.size():
		var section: Vector3 = sections[row]; var ring: Array = []; var liner: Array = []
		for col in 18:
			var a := TAU*float(col)/18
			var tear := sin(col*2.31+seed_value)*.22 if row==sections.size()-1 else 0.0
			var dent := 1.0-.10*pow(maxf(0,sin(col*1.7+row)),4)
			ring.append(Vector3(cos(a)*section.y*dent,center_y+sin(a)*section.z*dent,section.x+tear))
			liner.append(Vector3(cos(a)*(section.y-.09)*dent,center_y+sin(a)*(section.z-.09)*dent,section.x+tear))
		rings.append(ring); inside.append(liner)
	for row in sections.size()-1:
		for col in 18:
			var j := (col+1)%18
			SM._triangle(tools[0],rings[row][col],rings[row+1][col],rings[row+1][j]); SM._triangle(tools[0],rings[row][col],rings[row+1][j],rings[row][j])
			SM._triangle(tools[1],inside[row][col],inside[row+1][j],inside[row+1][col]); SM._triangle(tools[1],inside[row][col],inside[row][j],inside[row+1][j])
	for col in 18:
		var j := (col+1)%18
		SM._triangle(tools[1],rings[-1][col],rings[-1][j],inside[-1][j]); SM._triangle(tools[1],rings[-1][col],inside[-1][j],inside[-1][col])
	SM._part(root,tools[0].commit(),outer); SM._part(root,tools[1].commit(),inner)
