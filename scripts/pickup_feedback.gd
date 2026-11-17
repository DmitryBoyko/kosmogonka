extends Node3D
## Eight reusable REEBOO pickup flashes with a brief aura and HUD feedback.
const SHADER=preload("res://assets/surfaces/pickup_bloom.gdshader")
const LOOT_FLASH=preload("res://assets/effects/star_loot/loot_flash.gdshader")
const Stars = preload("res://scripts/collectible_star.gd")
const POOL_SIZE:=8
const FLASH_OPACITY := .20
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
	var mat := ShaderMaterial.new()
	mat.shader = SHADER if is_aura else LOOT_FLASH
	if is_aura: mat.set_shader_parameter("aura", true)
	else: mat.set_shader_parameter("billboard", false)
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
	effect.set_meta("contact", effect.position)
	var tint := Stars.value_color(amount)
	aura.material_override.set_shader_parameter("star_color", tint)
	effect.material_override.set_shader_parameter("color", tint)
	badge.add_theme_color_override("font_color", tint.lerp(Color.WHITE, .18))
	effect.scale=Vector3.ONE*(1.6 if mega else lerpf(1., 1.44, float(clampi(amount, 1, 5) - 1) / 4.))
	effect.set_meta("size",effect.scale.x)
	effect.material_override.set_shader_parameter("shape", 4 if mega else 1)
	effect.material_override.set_shader_parameter("energy", (2.8 if mega else 1.7) + suit_fx * .3)
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
	aura.material_override.set_shader_parameter("strength",FLASH_OPACITY*energy*(.65 if reduced_motion else 1.))
	aura.material_override.set_shader_parameter("reduced",reduced_motion)
	for i in POOL_SIZE:
		burst_ages[i]+=dt
		var burst := bursts[i]
		burst.visible=burst_ages[i]<.48
		if not burst.visible: continue
		if burst.visible and not reduced_motion:
			var contact: Vector3 = burst.get_meta("contact")
			burst.position = contact.lerp(at + Vector3.UP * 1.3, smoothstep(.025, .32, burst_ages[i]))
		var phase := burst_ages[i] / .48
		var scale_value := float(burst.get_meta("size")) * (1. if reduced_motion else lerpf(.55, 1.15, ease(phase, .45)))
		burst.basis = camera.global_basis.scaled(Vector3.ONE * scale_value)
		burst.material_override.set_shader_parameter("alpha", FLASH_OPACITY * (1. - smoothstep(.04, 1., phase)) * (.48 if reduced_motion else .72 if high_quality else .58))
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
