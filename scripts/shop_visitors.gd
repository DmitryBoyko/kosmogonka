extends Node3D
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Suit=preload("res://scripts/suit.gd")
const Shops=preload("res://scripts/monument_shops.gd")
var visitors:Array[Dictionary]=[]
var clock:=0.
func populate(seed_value:int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var first_shop:int=rng.randi_range(0,2)
	for i in rng.randi_range(1,3):
		var root:=Node3D.new();add_child(root);root.name="AlienShopper%d"%i
		var girl:bool=rng.randf()<.5;root.set_meta("girl",girl)
		var skin:String="equipment_t%d"%rng.randi_range(1,5);root.set_meta("suit_skin",skin)
		var shell:=Suit.material_for(skin,"shell")
		var fabric:=Suit.material_for(skin,"fabric").duplicate() as StandardMaterial3D
		var trim:=Suit.material_for(skin,"trim").duplicate() as StandardMaterial3D
		var tint:=Color(["5688a7","9171b6","c28b55","5a9f87","be6f95"][rng.randi_range(0,4)])
		fabric.albedo_color=tint;trim.albedo_color=tint.lightened(.25);root.set_meta("outfit_color",tint)
		var body:=Node3D.new();root.add_child(body)
		SM.block(body,Vector3(.85,.87,.55),Vector3(0,1.4,0),fabric,.13)
		SM.block(body,Vector3(.5,.40,.065),Vector3(0,1.5,.3),shell,.04)
		var badge:=preload("res://scripts/chest_badge.gd").build(1);body.add_child(badge);badge.position=Vector3(0,1.5,.34);badge.scale=Vector3.ONE*.7
		SM.block(body,Vector3(.64,.75,.3),Vector3(0,1.4,-.44),trim,.08)
		for side in [-1.,1.]:G.tube(body,.12,.47,Vector3(side*.23,1.25,-.63),"566b83")
		var limbs:Array[Node3D]=[]
		for side in [-1.,1.]:
			var arm:=Node3D.new();body.add_child(arm);arm.position=Vector3(side*.54,1.7,0);limbs.append(arm)
			arm.set_meta("motion","shop_limb")
			G.ball(arm,Vector3.ONE*.32,Vector3.ZERO).material_override=trim
			G.tube(arm,.12,.54,Vector3(0,-.28,0),"ffffff").material_override=fabric
			G.ring(arm,.12,.16,Vector3(0,-.35,0)).material_override=trim
			G.ball(arm,Vector3(.26,.26,.28),Vector3(0,-.60,.02)).material_override=shell
			var leg:=Node3D.new();body.add_child(leg);leg.position=Vector3(side*.24,1.,0);limbs.append(leg)
			leg.set_meta("motion","shop_limb")
			G.tube(leg,.15,.60,Vector3(0,-.32,0),"ffffff").material_override=fabric
			G.ring(leg,.15,.19,Vector3(0,-.50,0)).material_override=trim
			SM.block(leg,Vector3(.35,.28,.47),Vector3(0,-.84,.10),shell,.06)
			G.merge_static(arm);G.merge_static(leg)
		G.ring(body,.38,.47,Vector3(0,1.88,0),"d4ecf1")
		var head:=Node3D.new();body.add_child(head);head.position.y=2.22
		head.set_meta("motion","shop_head")
		var color:String=["a3dca7","c2ade9","edb894","80d8d8"][rng.randi_range(0,3)]
		G.ball(head,Vector3(.85,.74,.72),Vector3.ZERO,color)
		G.ball(head,Vector3(.24,.035,.05),Vector3(0,-.27,.34),"466072")
		for side in [-1.,1.]:
			G.link(head,Vector3(side*.22,.27,0),Vector3(side*.34,.55,0),.035,color)
			G.ball(head,Vector3.ONE*(.17 if girl else .11),Vector3(side*.34,.55,0),"ffadcf" if girl else "8ef9ed",.1)
		var eyes:Array[Node3D]=[]
		for j in 3:
			var eye:=Node3D.new();head.add_child(eye);eyes.append(eye)
			eye.set_meta("motion","shop_eye")
			G.ball(eye,Vector3(.22,.24,.16),Vector3.ZERO,"eefbff")
			G.ball(eye,Vector3(.105,.13,.055),Vector3(0,0,.085),"284866")
			G.ball(eye,Vector3.ONE*.035,Vector3(-.025,.025,.12),"ffffff")
			G.merge_static(eye)
		G.merge_static(head);G.merge_static(body)
		var collider:=StaticBody3D.new();root.add_child(collider);collider.collision_layer=4;collider.collision_mask=0
		var shape:=CollisionShape3D.new();shape.shape=CapsuleShape3D.new();shape.shape.radius=.48;shape.shape.height=2.8;shape.position.y=1.4;collider.add_child(shape)
		var shop:int=(first_shop+i)%3;var at:Vector3=Shops.POSITIONS[shop];var inward:Vector3=Vector3(-signf(at.x)*6.,0,0) if shop<2 else Vector3(0,0,6.)
		visitors.append({"node":root,"body":body,"head":head,"limbs":limbs,"eyes":eyes,"home":at+inward,"phase":rng.randf()*TAU,"speed":rng.randf_range(.24,.35)})
	advance(0.)
func advance(dt:float) -> void:
	clock+=dt
	for v:Dictionary in visitors:
		var moving:bool=fposmod(clock+v.phase,13.)<9.
		if moving:v.phase+=dt*v.speed
		v.node.position=v.home+Vector3(cos(v.phase)*1.5,0,sin(v.phase)*1.7)
		v.node.rotation.y=-v.phase if moving else v.node.rotation.y
		v.body.position.y=absf(sin(clock*4.))*0.035 if moving else sin(clock*1.4)*.01
		for i in v.limbs.size():v.limbs[i].rotation.x=sin(clock*4.+i*PI)*.30 if moving else 0.
		for j in 3:
			var angle:float=clock*.65+j*TAU/3.
			v.eyes[j].position=Vector3(cos(angle)*.20,sin(angle)*.19,.33)
			v.eyes[j].rotation.z=-angle*.4
