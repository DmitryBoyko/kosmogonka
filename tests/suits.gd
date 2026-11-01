extends SceneTree
const Hero=preload("res://scripts/hero.gd")
const Suit=preload("res://scripts/suit.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_value: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label_value)

func run() -> void:
	for girl in [false,true]:
		var hero=Hero.new()
		root.add_child(hero)
		hero.build(girl)
		for slot: String in Suit.SLOTS: check(not hero.suit_parts(slot).is_empty(),"populated appearance slot: "+slot)
		var cloth: StandardMaterial3D=Suit.material_for("explorer_mint","fabric")
		check(cloth.albedo_texture!=null and cloth.albedo_texture.get_image().has_mipmaps(),"woven fabric uses a real texture with mipmaps")
		check(cloth.roughness>Suit.material_for("explorer_mint","shell").roughness,"cloth and armor have different surface responses")
		var untouched: Dictionary={}
		for node in hero.find_children("*","MeshInstance3D",true,false):
			if not node.has_meta("suit_slot"): untouched[node.get_instance_id()]=node.material_override
		for i in 30: hero.animate(1.0/60,"run",18)
		var before: Transform3D=hero.arms[0].transform
		var right: Material=hero.suit_parts("right_glove")[0].material_override
		var left: Material=hero.suit_parts("left_glove")[0].material_override
		var loadout: Dictionary=hero.suit_loadout.duplicate(true)
		loadout.slots.left_glove="solar_rescue"
		hero.apply_suit(loadout)
		check(hero.suit_parts("left_glove")[0].material_override!=left,"one glove can use a different skin")
		check(hero.suit_parts("right_glove")[0].material_override==right,"changing the left glove preserves the right glove")
		check(hero.arms[0].transform.is_equal_approx(before),"swapping skin does not reset the running pose")
		var same:=true
		for id in untouched:
			var node: MeshInstance3D=instance_from_id(id)
			same=same and node.material_override==untouched[id]
		check(same,"appearance changes leave faces, hair, flames and vehicle untouched")
		check(hero.suit_sockets.has("left_forearm") and hero.suit_sockets.has("right_shin"),"future meshes have articulated attachment sockets")
		var wrist: Node3D=hero.suit_sockets.left_glove
		check(wrist.get_parent()==hero.hands[0],"glove socket follows the animated wrist")
		var normalized:=Suit.normalize({"version":1,"slots":{"torso":"missing","unknown":"solar_rescue"}},girl)
		check(normalized.slots.size()==Suit.SLOTS.size() and not normalized.slots.has("unknown"),"unknown slots are excluded from saved loadouts")
		check(normalized.slots.torso==("explorer_rose" if girl else "explorer_mint"),"missing skins fall back safely")
		var cfg:=ConfigFile.new()
		cfg.set_value("appearance","loadout",hero.suit_loadout)
		cfg.save("res://build/suit-roundtrip.cfg")
		var restored:=ConfigFile.new()
		restored.load("res://build/suit-roundtrip.cfg")
		check(Suit.normalize(restored.get_value("appearance","loadout"),girl)==hero.suit_loadout,"mixed-part loadout survives save/load")
		hero.free()
	print("SUITS: %d checks, %d failures" % [checks,failures])
	await process_frame
	quit(1 if failures else 0)
