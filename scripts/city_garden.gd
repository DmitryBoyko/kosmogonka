extends RefCounted
const G=preload("res://scripts/geometry.gd")
static var leaves:Dictionary={}
static var petal_mesh:SphereMesh
static func petal(root:Node3D, size:Vector3, at:Vector3, color:String) -> void:
	if petal_mesh==null:
		petal_mesh=SphereMesh.new(); petal_mesh.radius=.5; petal_mesh.height=1
		petal_mesh.radial_segments=8; petal_mesh.rings=4
	G.part(root,petal_mesh,at,G.material(color)).scale=size
static func foliage(variant:int=0) -> ShaderMaterial:
	if leaves.has(variant): return leaves[variant]
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/finish_city/bio_foliage.gdshader")
	mat.set_shader_parameter("leaf_color",Color(["338768","379c83","628d50","398c8a"][variant%4]))
	mat.set_shader_parameter("flower_color",Color(["ff94c4","ffc873","db9dff","ffe8a3"][variant%4]))
	leaves[variant]=mat; return mat

static func flower(root:Node3D, at:Vector3, variant:int) -> void:
	G.link(root,at,at+Vector3(.08,.55,0),.025,"508c62")
	var color:String=["ff82b1","ffce72","c99bff","fff1b4"][variant%4]
	for i in 5:
		var a:=i*TAU/5
		petal(root,Vector3(.22,.12,.3),at+Vector3(sin(a)*.15,.56,cos(a)*.15),color)
	petal(root,Vector3(.16,.14,.16),at+Vector3(0,.61,0),"ffe6a3")

static func bed(root:Node3D, at:Vector3, variant:int) -> void:
	G.ball(root,Vector3(3.6,.35,2.4),at,"c4c8b7")
	G.ball(root,Vector3(3.3,.22,2.1),at+Vector3(0,.12,0),"365b4b").material_override=foliage(variant)
	for i in 9:
		flower(root,at+Vector3((i%3-1)*.85,.20,(i/3-1)*.55),variant+i)

static func tree(root:Node3D,at:Vector3,variant:int) -> void:
	preload("res://scripts/natural_flora.gd").tree(root,at,variant,int(at.z*13+at.x*19))

static func entrance(root:Node3D, at:Vector3, index:int, planet:int, height:float) -> void:
	var porch:=Node3D.new(); root.add_child(porch)
	var inward:=Vector3(-signf(at.x),0,0) if absf(at.x)>45 else Vector3(0,0,1 if at.z<0 else -1)
	porch.position=at+inward*8.2
	porch.rotation.y=atan2(inward.x,inward.z)
	G.box(porch,Vector3(5,.15,6),Vector3(0,.05,2.7),"b6c4b6")
	for side in [-1,1]:
		G.box(porch,Vector3(.10,.04,5.6),Vector3(side*2.1,.15,2.7),"8ef4d5",.3)
		G.tube(porch,.12,2.8,Vector3(side*2,1.4,.8),"547b81")
		bed(porch,Vector3(side*3.9,.2,3),index+planet)
	G.ball(porch,Vector3(5.5,.35,3.8),Vector3(0,3.05,.3),"e2cead")
	G.ball(porch,Vector3(5.1,.22,3.3),Vector3(0,3.24,.3),"4da87e").material_override=foliage(planet)
	G.box(porch,Vector3(1.9,2.6,.13),Vector3(0,1.3,0),"254e63")
	G.box(porch,Vector3(.07,2.1,.15),Vector3(.4,1.25,.08),"9dffe4",.3)
	G.label(porch,["БИО / ЛАБ","ОРБИТА / КАФЕ","САД / 07","ФЛОРА / ДОМ"][index%4],Vector3(0,2.75,.9),24)
	for floor in range(5,int(height*.6),4):
		for side in [-1,1]:
			var pos:=Vector3(side*3.6,floor,-2.0-float(floor)/height*2.8)
			G.link(porch,pos+Vector3(0,-.2,.3),pos+Vector3(0,-1.1,-1),.09,"547b81")
			G.box(porch,Vector3(2.6,.35,1.2),pos,"b4c9bb")
			G.ball(porch,Vector3(2.8,.8,1.5),pos+Vector3(0,.35,.15),"58ac78").material_override=foliage(index+planet)
			for bloom in 3: flower(porch,pos+Vector3((bloom-1)*.7,.5,.65),index+bloom)

static func plaza(root:Node3D, planet:int) -> void:
	var garden:=Node3D.new(); garden.name="FlowerGardens"; root.add_child(garden)
	for side in [-1,1]:
		for i in 4:
			var at:=Vector3(side*36.5,-.1,-55+i*19)
			bed(garden,at,planet+i); tree(garden,at+Vector3(side*1.5,0,0),planet)
		for i in 3:
			bed(garden,Vector3(side*(10+i*9),-.1,16),planet+i)
		# Open landscaped approaches replace the old wall and gate.
		G.box(garden,Vector3(7,.08,16),Vector3(side*18,-.12,24),"a4b7b0")
		for i in 4: flower(garden,Vector3(side*22,.05,19+i*3),i+planet)
	preload("res://scripts/natural_flora.gd").grass(garden,planet,543,Vector2(84,84),Vector3(0,-.20,-24))
	G.batch(garden)
	root.set_meta("flower_gardens",true)
