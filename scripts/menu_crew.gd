extends RefCounted
## A self-contained greeting/play scene. Never controls the actual runner.
signal laugh(girl: bool)
const PREVIEW_SCALE:=1.15
var active:=false
var mode:="idle"
var time:=0.0
var wait:=1.4
var initiator:=0
var contact_count:=0
var rng:=RandomNumberGenerator.new()
func _init() -> void: rng.randomize()

func reset(kids:Array, enabled:bool=false) -> void:
	active=enabled; mode="idle"; time=0; wait=rng.randf_range(1.2,2.8); contact_count=0
	for i in kids.size():
		var kid=kids[i]
		kid.position=Vector3(-.95 if i==0 else .95,.45,0)
		kid.rotation=Vector3(0,.12 if i==0 else -.12,0)
		kid.scale=Vector3.ONE*PREVIEW_SCALE
		kid.menu_expression=-1; kid.menu_jet=false; kid.cancel_front_gesture(); kid.jet_fx.advance(0,false)
		kid.animate(.2,"idle")

func start(kind:String, who:int) -> void:
	mode=kind; initiator=who; time=0; contact_count=0

func flow_ease(value:float) -> float:
	var u:=clampf(value,0,1)
	return u*u*u*(10-u*(15-6*u))

func advance(dt:float,kids:Array,reduced:bool=false) -> void:
	if not active: reset(kids,true)
	time+=dt
	if mode=="idle" and time>=wait:
		start("duel" if rng.randf()<.35 else "greet",rng.randi_range(0,1))
	var direction:=1.0 if initiator==0 else -1.0
	for i in kids.size():
		var kid=kids[i]; var side:float=-1.0 if i==0 else 1.0
		kid.position=Vector3(side*.95,.45,0); kid.rotation=Vector3(0,-side*.12,0)
		kid.scale=Vector3.ONE*PREVIEW_SCALE
		var greeting:=mode=="greet" and i==initiator
		var smile:=smoothstep(0,.25,time)*(1-smoothstep(1.5,1.9,time)) if greeting else .9 if mode=="duel" else 0.0
		kid.menu_expression=smile
		var launch_start:=3.6 if i==initiator else .65
		var q:float=(time-launch_start)/2.4
		kid.menu_jet=mode=="duel" and q>.12 and q<1.0
		kid.animate(dt,"idle")
		if greeting:
			kid.gesture_ik(1,Vector3(.78+sin(time*16)*.035,2.0,.18),Vector3.RIGHT,smile)
			kid.hands[1].rotation.z=sin(time*16)*.3*smile
			kid.head.rotation.y=lerp_angle(kid.head.rotation.y,0,smile)
		if mode!="duel": continue
		var push_start:=0.0 if i==initiator else 2.95
		var towards:float=direction if i==initiator else -direction
		var push_time:=time-push_start
		if push_time>=0 and push_time<1.25:
			var lean:=smoothstep(0,.6,push_time)*(1-smoothstep(.75,1.25,push_time))
			kid.position.x+=towards*.35*lean
			kid.rotation.y+=towards*.45*lean
			kid.body.rotation.z-=towards*.12*lean
			kid.head.rotation.y=towards*.35*lean
			var hand:=1 if towards>0 else 0
			kid.gesture_ik(hand,Vector3(towards*.90,1.33,.18),Vector3(towards,0,0),lean)
		if q>=0 and q<=1:
			var away:float=-towards
			var drift:float=.91*(flow_ease(q/.4) if q<=.4 else 1-flow_ease((q-.4)/.6))
			var arc:=sin(flow_ease(q)*PI)
			var travel:=.28 if reduced else 1.0
			kid.position.x+=away*drift*travel
			kid.position.y+=arc*(.13 if reduced else .65)
			kid.rotation.y+=-away*.65*arc
			kid.rotation.z=away*lerpf(-.25,.2,flow_ease((q-.18)/.26))*arc
			kid.head.rotation.y=-away*.4*arc
			if kid.menu_jet:
				for jet in kid.jet_fx.jets: jet.scale.y*=1.25
				var fade:=1-flow_ease((q-.8)/.2)
				for mat in kid.jet_fx.materials: mat.set_shader_parameter("power",kid.jet_fx.power*fade)
				for light in kid.jet_fx.lights: light.light_energy*=fade
			for arm in 2:
				kid.arms[arm].rotation.z=(-1 if arm==0 else 1)*lerpf(.18,1.05,arc)
				kid.legs[arm].rotation.x=(-.2 if arm==0 else .25)*arc
				kid.knees[arm].rotation.x=lerpf(.06,.2,arc)
	if mode=="duel":
		if time>=.65 and contact_count==0: contact_count=1; laugh.emit(initiator!=1)
		if time>=3.6 and contact_count==1: contact_count=2; laugh.emit(initiator==1)
	if (mode=="greet" and time>2.0) or (mode=="duel" and time>6.4):
		mode="idle"; time=0; wait=rng.randf_range(3.5,6.5)
