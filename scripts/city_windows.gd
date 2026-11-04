extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const G=preload("res://scripts/geometry.gd")
static var glass:StandardMaterial3D
static func glazing() -> Material:
	if glass: return glass
	glass=StandardMaterial3D.new(); glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color=Color(.48,.73,.81,.19); glass.roughness=.12; glass.metallic=.12
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	return glass

static func window(root:Node3D,at:Vector3,lit:bool,planet:int) -> void:
	var trim:String=["c8d8d5","c6e3c9","d8b88e","657b9e"][Planets.biome(planet)]
	var reveal:String=["6c8792","5c9584","9d876c","344b69"][Planets.biome(planet)]
	# Projecting bay: opaque backing is behind the glazing, never painted onto it.
	G.box(root,Vector3(1.75,1.9,.10),at+Vector3(0,0,-1.95),"273b4b")
	for side in [-1,1]:
		G.box(root,Vector3(.14,1.95,2.0),at+Vector3(side*.91,0,-.95),reveal)
		G.box(root,Vector3(1.9,.14,2.0),at+Vector3(0,side*.94,-.95),reveal)
		G.box(root,Vector3(.11,1.91,.15),at+Vector3(side*.91,0,.035),trim)
		G.box(root,Vector3(1.90,.11,.15),at+Vector3(0,side*.94,.035),trim)
	G.box(root,Vector3(2.1,.14,.92),at+Vector3(0,-1.02,-.26),trim)
	# A visible inner room, sill and curtain create genuine parallax when walking past.
	G.box(root,Vector3(1.60,1.62,.04),at+Vector3(0,0,-1.85),"e6c997" if lit else "314857",.16 if lit else 0.)
	G.box(root,Vector3(.30,1.65,.16),at+Vector3(-.62,0,-.45),"987d83" if lit else "3b5761")
	G.box(root,Vector3(.54,.10,.34),at+Vector3(.22,-.50,-.38),"84634a")
	if lit: G.ball(root,Vector3(.22,.30,.22),at+Vector3(.3,.25,-.45),"ffe9a4",.35)
	var pane:=QuadMesh.new(); pane.size=Vector2(1.67,1.73)
	G.part(root,pane,at+Vector3(0,0,-.07),glazing()).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.box(root,Vector3(.055,1.76,.08),at+Vector3(0,0,-.025),trim)
	G.box(root,Vector3(1.7,.055,.08),at+Vector3(0,-.25,-.025),trim)

static func facade(root:Node3D,at:Vector3,height:float,index:int,planet:int) -> void:
	var holder:=Node3D.new(); root.add_child(holder)
	var inward:=Vector3(-signf(at.x),0,0) if absf(at.x)>45 else Vector3(0,0,1 if at.z<0 else -1)
	holder.position=at+inward*8.6; holder.rotation.y=atan2(inward.x,inward.z)
	for floor in range(3,int(height*.52),3):
		for col in 4:
			window(holder,Vector3((col-1.5)*2.65,floor,0),posmod(index+floor+col,4)!=0,planet)
