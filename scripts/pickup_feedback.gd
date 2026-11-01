extends Node3D
## One pooled "star resonance": outside-in orbital ribbons and an overhead receipt.
const SHADER=preload("res://assets/suits/star_resonance.gdshader")
var ribbon: MeshInstance3D
var material: ShaderMaterial
var badge: Label
var canvas: Control
var counter: Label
var energy:=0.0
var age:=10.0
var group_age:=10.0
var total:=0
var phase:=0.0
var reduced_motion:=false
var high_quality:=true

func build(canvas_parent: Control, score_counter: Label = null) -> void:
	canvas=canvas_parent
	counter=score_counter
	badge=Label.new()
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size",24)
	badge.add_theme_color_override("font_color",Color("ffe9ad"))
	badge.add_theme_color_override("font_outline_color",Color("3e354f"))
	badge.add_theme_constant_override("outline_size",5)
	badge.size=Vector2(150,36)
	badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	badge.visible=false
	canvas.add_child(badge)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for arc in 3:
		for segment in 32:
			for uv: Vector2 in [Vector2(segment,0),Vector2(segment+1,1),Vector2(segment+1,0),Vector2(segment,0),Vector2(segment,1),Vector2(segment+1,1)]:
				var t:=uv.x/32.0
				var angle:=arc*TAU/3+t*PI*1.3
				var radius:=0.90-t*0.17
				st.set_uv(Vector2(t,uv.y))
				st.add_vertex(Vector3(cos(angle)*radius,0.42+t*1.12+(uv.y-0.5)*0.10,sin(angle)*radius))
	material=ShaderMaterial.new()
	material.shader=SHADER
	ribbon=MeshInstance3D.new()
	add_child(ribbon)
	ribbon.mesh=st.commit()
	ribbon.material_override=material
	ribbon.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ribbon.visible=false

func notify(amount: int) -> void:
	if amount<=0: return
	if age>0.5 or group_age>0.8:
		total=0
		group_age=0
		age=0
	else: age=minf(age,0.12)
	total+=amount
	badge.text="✦ +%d" % total
	energy=minf(1.0,energy+0.65)

func advance(dt: float, at: Vector3, camera: Camera3D, active: bool, receipt_at: Vector3 = Vector3.INF) -> void:
	if not active:
		ribbon.visible=false
		badge.visible=false
		if is_instance_valid(counter): counter.scale=Vector2.ONE
		return
	position=at
	age+=dt
	group_age+=dt
	phase+=dt
	energy*=exp(-dt*6)
	ribbon.visible=high_quality and energy>0.035
	ribbon.rotation.y=0 if reduced_motion else phase*1.7
	var radius:=1.0+energy*0.12
	ribbon.scale=Vector3(radius,1,radius)
	material.set_shader_parameter("energy",energy)
	badge.visible=age<0.55
	if badge.visible:
		var point:=camera.unproject_position(at+Vector3(0,3.0,0) if not receipt_at.is_finite() else receipt_at)
		var bounds:=camera.get_viewport().get_visible_rect().size
		var lift:=0.0 if reduced_motion else age*22
		point.x=clampf(point.x-badge.size.x/2,12,bounds.x-badge.size.x-12)
		point.y=clampf(point.y-badge.size.y-lift,170,bounds.y-145)
		badge.global_position=point
		badge.modulate.a=(1.0-smoothstep(0.2,0.55,age))*minf(1.0,age/0.04)
	if is_instance_valid(counter):
		counter.pivot_offset=counter.size*0.5
		counter.scale=Vector2.ONE*(1.0+(0 if reduced_motion else energy*0.045))

func reset() -> void:
	energy=0
	age=10
	group_age=10
	total=0
	if is_instance_valid(ribbon): ribbon.visible=false
	if is_instance_valid(badge): badge.visible=false
	if is_instance_valid(counter): counter.scale=Vector2.ONE

func _exit_tree() -> void:
	if is_instance_valid(badge): badge.queue_free()
