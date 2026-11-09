extends Node3D
const G=preload("res://scripts/geometry.gd")
const Kit=preload("res://scripts/shop_ship_kit.gd")
var actor:Node3D
var environment:Environment
var yaw:=.12
var zoom:=1.
var pointer:=-3
var last_point:=Vector2.ZERO
var girl:=false
var fingers:Dictionary={}
var pinch_distance:=0.
var canvas_height:=960.
var home_yaw:=.12
var key_light:SpotLight3D
func build() -> void:
	name="OrbitalFittingRoom"; position=Vector3(1000,0,0)
	var shell:=SphereMesh.new(); shell.radius=35.; shell.height=70.; shell.radial_segments=16; shell.rings=8
	var sky:=StandardMaterial3D.new(); sky.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; sky.cull_mode=BaseMaterial3D.CULL_FRONT; sky.albedo_color=Color("091425")
	G.part(self,shell,Vector3.ZERO,sky)
	Kit.model(self,"Platform_CenterPlate",Vector3(0,0,0),Vector3(4.9,.16,4.9))
	for side in [-1,1]:
		Kit.model(self,"Column_MetalSupport",Vector3(side*2.65,.16,-2.4),Vector3(.38,4.7,.5))
		G.box(self,Vector3(.045,3.8,.045),Vector3(side*2.36,2.5,-2.07),"5aafc6",.25)
	Kit.model(self,"Prop_Computer",Vector3(-2.55,.16,.25),Vector3(.8,1.5,.65),.35)
	var back:=G.box(self,Vector3(5.8,5.3,.18),Vector3(0,2.65,-2.6),"182b40")
	back.material_override=preload("res://scripts/salvage_materials.gd").material("hull-titanium",true)
	key_light=SpotLight3D.new(); add_child(key_light); key_light.position=Vector3(1.2,4.3,4.); key_light.spot_range=13.; key_light.spot_angle=58.; key_light.light_energy=2.; key_light.light_color=Color("dfedff")
	key_light.look_at(global_position+Vector3(0,2.4,0)); key_light.shadow_enabled=true
	var rim:=OmniLight3D.new(); add_child(rim); rim.position=Vector3(-2.2,3.,-.8); rim.omni_range=8.; rim.light_energy=1.2; rim.light_color=Color("80c8e1")
	environment=Environment.new(); environment.background_mode=Environment.BG_COLOR; environment.background_color=Color("091425"); environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; environment.ambient_light_color=Color("a3b7cd"); environment.ambient_light_energy=.6
func show_outfit(is_girl:bool,outfit:Dictionary,base:Dictionary) -> void:
	if not is_instance_valid(actor) or girl!=is_girl:
		if is_instance_valid(actor): actor.free()
		actor=preload("res://scripts/hero.gd").new(); add_child(actor); girl=is_girl; actor.build(girl,base)
	actor.position=Vector3(0,.17,0); actor.scale=Vector3.ONE*1.75; actor.shadow_ground=.16
	actor.apply_outfit(outfit)
func face_category(category:String) -> void:
	home_yaw=PI if category=="pack" else .12; yaw=home_yaw
func _input(event:InputEvent) -> void:
	# A release over UI is handled before _unhandled_input; don't retain a finger.
	if event is InputEventScreenTouch and not event.pressed:
		fingers.erase(event.index); pinch_distance=0.
		if pointer==event.index: pointer=-3
func advance(dt:float,camera:Camera3D,canvas_size:Vector2,category:String) -> void:
	canvas_height=canvas_size.y
	if not is_instance_valid(actor): return
	actor.rotation.y=yaw; actor.animate(dt,"board" if category=="board" else "idle")
	var distance_value:float=8.5/zoom
	camera.position=global_position+Vector3(0,2.85,distance_value); camera.look_at(global_position+Vector3(0,2.75,0)); camera.fov=43.
	var meter_per_pixel:float=2.*tan(deg_to_rad(43.)*.5)*distance_value/540.
	camera.h_offset=104.*meter_per_pixel
	camera.v_offset=-(55.+maxf(0.,canvas_size.y-960.)*.25)*meter_per_pixel
func input(event:InputEvent) -> bool:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT: yaw-=.15; return true
			KEY_RIGHT: yaw+=.15; return true
			KEY_EQUAL,KEY_KP_ADD: zoom=clampf(zoom+.08,.8,1.25); return true
			KEY_MINUS,KEY_KP_SUBTRACT: zoom=clampf(zoom-.08,.8,1.25); return true
			KEY_HOME: yaw=home_yaw; zoom=1.; return true
	var bottom:float=605.+maxf(0.,canvas_height-960.)*.5
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x<300 and event.position.y>245 and event.position.y<bottom: fingers[event.index]=event.position
		else: fingers.erase(event.index)
		if fingers.size()==2: pinch_distance=fingers.values()[0].distance_to(fingers.values()[1]); pointer=-3; return true
		if not event.pressed: pinch_distance=0.
	if event is InputEventScreenDrag and fingers.has(event.index):
		fingers[event.index]=event.position
		if fingers.size()==2:
			var next:float=fingers.values()[0].distance_to(fingers.values()[1])
			if pinch_distance>1.: zoom=clampf(zoom*next/pinch_distance,.8,1.25)
			pinch_distance=next; return true
	var point:=Vector2.ZERO; var pressed:=false; var released:=false; var id:=-3
	if event is InputEventScreenTouch: point=event.position; pressed=event.pressed; released=not pressed; id=event.index
	elif event is InputEventScreenDrag: point=event.position; id=event.index
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.position.x<300 and event.position.y>245 and event.position.y<bottom:
			zoom=clampf(zoom+(.08 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -.08),.8,1.25); return true
		if event.button_index!=MOUSE_BUTTON_LEFT: return false
		point=event.position; pressed=event.pressed; released=not pressed; id=-1
	elif event is InputEventMouseMotion and pointer==-1: point=event.position; id=-1
	else: return false
	if pressed and point.x<300 and point.y>245 and point.y<bottom: pointer=id; last_point=point
	if pointer!=id: return false
	if released: pointer=-3
	else: yaw+=(point.x-last_point.x)*.012; last_point=point
	return true
