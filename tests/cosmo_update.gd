extends SceneTree

const Crew = preload("res://scripts/crew.gd")
const Catalog = preload("res://scripts/outfit_catalog.gd")
const Avatar = preload("res://scripts/crew_avatar.gd")
const Course = preload("res://scripts/course.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func run() -> void:
	var p := root.get_node("Profile")
	p.persistence_enabled = false
	var armor := {}
	p.hero = 0
	p.owned_items.clear()
	for part: String in Catalog.ARMOR:
		var id := part+"_12"
		armor[part]=id
		p.owned_items.append(id)
	p.owned_items.append("gloves_11")
	p.outfits[0]=armor
	check(p.heart_purchase_limit()==10,"Full level 12 allows ten purchases")
	p.outfits[0]["gloves"]="gloves_11"
	check(p.heart_purchase_limit()==9,"Weakest part controls limit")
	p.credit_heart(0)
	var previous: int = p.heart_count()
	p.outfits[0]={}
	check(p.heart_count()==previous and p.heart_purchase_limit()==3,"Lower armor keeps existing reserve")
	var alien := Avatar.new()
	root.add_child(alien)
	alien.build(Crew.ALIEN_GUY)
	alien.pose("run")
	check(alien.animation.assigned_animation=="Running Cycle","Alien has its original run cycle")
	alien.pose("walk")
	check(alien.animation.assigned_animation=="Walking Cycle","Alien has its original walk cycle")
	check(alien.rig.find_children("*","MeshInstance3D",true,false).size()>0 and alien.panels.is_empty(),"Original alien suit stays intact")
	for world in range(19):
		var events := Course.events(world)
		check(events.any(func(e: Dictionary) -> bool: return e.obstacle_type=="technical"),"Technical obstacles on %d"%world)
		check(events.any(func(e: Dictionary) -> bool: return e.obstacle_type=="biome"),"Biome obstacles on %d"%world)
	root.remove_child(alien)
	alien.free()
	print("COSMO UPDATE: %d failures"%failures)
	quit(1 if failures else 0)
