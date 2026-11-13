extends Node3D
## Bounded arcade feedback: brief contact flash, expanding aura, eight glints.
const SHADER=preload("res://assets/surfaces/pickup_bloom.gdshader")
const POOL_SIZE:=8
var bursts:Array[MeshInstance3D]=[]
var burst_ages:Array[float]=[]
var aura:MeshInstance3D
var badge:Label
var canvas:Control
var counter:Label
var energy:=0.0
var age:=10.0
var group_age:=10.0
var total:=0
var special:=false
var cursor:=0
var reduced_motion:=false
var high_quality:=true
var suit_fx:=0.

func quad(size_value:float,is_aura:bool=false) -> MeshInstance3D:
	var mesh:=QuadMesh.new(); mesh.size=Vector2.ONE*size_value
	var node:=MeshInstance3D.new(); node.mesh=mesh
	var mat:=ShaderMaterial.new(); mat.shader=SHADER; mat.set_shader_parameter("aura",is_aura)
	node.material_override=mat; node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visible=false; add_child(node); return node

func build(canvas_parent:Control,score_counter:Label=null) -> void:
	canvas=canvas_parent; counter=score_counter
	badge=Label.new(); badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size",27)
	badge.add_theme_color_override("font_color",Color("fff0b2"))
	badge.add_theme_color_override("font_outline_color",Color("493452"))
	badge.add_theme_constant_override("outline_size",5)
	badge.size=Vector2(180,40); badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	badge.visible=false; canvas.add_child(badge)
	aura=quad(3.3,true)
	for i in POOL_SIZE:
		bursts.append(quad(2.6)); burst_ages.append(10.)

func notify(amount:int,contact:Vector3=Vector3.INF,mega:bool=false) -> void:
	if amount<=0: return
	if age>.38 or group_age>1.0:
		total=0; group_age=0; special=false
	total+=amount; special=special or amount>1
	age=0; energy=minf(1.,energy+.75)
	badge.text=("×2  " if special and amount==2 else "✦  ")+"+%d"%total
	var effect:=bursts[cursor]
	effect.position=contact if contact.is_finite() else Vector3(0,1.5,0)
	effect.scale=Vector3.ONE*(1.6 if mega else 1.35 if amount>1 else 1.)
	effect.set_meta("size",effect.scale.x)
	effect.material_override.set_shader_parameter("special",1.0 if amount>1 else 0.)
	effect.material_override.set_shader_parameter("suit_fx",suit_fx)
	burst_ages[cursor]=0; cursor=(cursor+1)%POOL_SIZE

func advance(dt:float,at:Vector3,camera:Camera3D,active:bool,receipt_at:Vector3=Vector3.INF) -> void:
	if not active:
		aura.visible=false; badge.visible=false
		for burst in bursts: burst.visible=false
		if is_instance_valid(counter): counter.scale=Vector2.ONE
		return
	age+=dt; group_age+=dt; energy*=exp(-dt*8)
	aura.position=at+Vector3(0,1.3,0); aura.basis=camera.global_basis
	aura.visible=energy>.025
	aura.material_override.set_shader_parameter("age",minf(1.,age/.36))
	aura.material_override.set_shader_parameter("strength",energy*(.65 if reduced_motion else 1.))
	aura.material_override.set_shader_parameter("reduced",reduced_motion)
	for i in POOL_SIZE:
		burst_ages[i]+=dt
		var burst:=bursts[i]; burst.basis=camera.global_basis.scaled(Vector3.ONE*float(burst.get_meta("size",burst.scale.x)))
		burst.visible=burst_ages[i]<.48
		var mat:ShaderMaterial=burst.material_override
		mat.set_shader_parameter("age",minf(1.,burst_ages[i]/.48))
		mat.set_shader_parameter("strength",.55 if reduced_motion else 1.)
		mat.set_shader_parameter("reduced",reduced_motion or not high_quality)
	badge.visible=age<.48
	if badge.visible and camera.is_position_behind(at+Vector3(0,3.,0) if not receipt_at.is_finite() else receipt_at): badge.visible=false
	if badge.visible:
		var point:=camera.unproject_position(at+Vector3(0,3.,0) if not receipt_at.is_finite() else receipt_at)
		var bounds:=camera.get_viewport().get_visible_rect().size
		point.x=clampf(point.x-badge.size.x*.5,12,bounds.x-badge.size.x-12)
		point.y=clampf(point.y-badge.size.y-(0. if reduced_motion else 18.*(1.-pow(1.-minf(age/.48,1.),2.))),170,bounds.y-145)
		badge.global_position=point; badge.modulate.a=1.-smoothstep(.18,.48,age)
		badge.pivot_offset=badge.size*.5
		badge.scale=Vector2.ONE*(1.+(.0 if reduced_motion else .13*exp(-age*16)))
	if is_instance_valid(counter):
		counter.pivot_offset=counter.size*.5
		counter.scale=Vector2.ONE*(1.+(0. if reduced_motion else energy*(.07 if special else .045)))

func reset() -> void:
	energy=0; age=10; group_age=10; total=0; special=false
	if is_instance_valid(aura): aura.visible=false
	for i in bursts.size(): bursts[i].visible=false; burst_ages[i]=10
	if is_instance_valid(badge): badge.visible=false
	if is_instance_valid(counter): counter.scale=Vector2.ONE

func _exit_tree() -> void:
	if is_instance_valid(badge): badge.queue_free()
