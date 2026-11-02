extends RefCounted
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
## Seeded, grounded architecture. Every architectural piece has a load path to a foundation.
const NAMES := ["Храм затихшего солнца", "Город потерянных голосов", "Монумент Первого сигнала", "Обсерватория горизонта", "Святилище ступеней", "Врата памяти"]

static func block(root: Node3D, size: Vector3, at: Vector3, mat: Material, taper: float = .04) -> MeshInstance3D:
	# Chamfered octagonal footprint: weathered corners instead of perfect boxes.
	var b := minf(size.x,size.z)*.13
	var x := size.x*.5; var z := size.z*.5
	var outline := [Vector2(-x+b,-z),Vector2(x-b,-z),Vector2(x,-z+b),Vector2(x,z-b),Vector2(x-b,z),Vector2(-x+b,z),Vector2(-x,z-b),Vector2(-x,-z+b)]
	var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var j := (i+1)%8
		var a: Vector2 = outline[i]; var c: Vector2 = outline[j]
		var p := Vector3(a.x,-size.y*.5,a.y); var q := Vector3(c.x,-size.y*.5,c.y)
		var u := Vector3(a.x*(1-taper),size.y*.5,a.y); var v := Vector3(c.x*(1-taper),size.y*.5,c.y)
		SM._triangle(tool,p,q,v); SM._triangle(tool,p,v,u)
		SM._triangle(tool,Vector3(0,size.y*.5,0),u,v)
		SM._triangle(tool,Vector3(0,-size.y*.5,0),q,p)
	var node := SM._part(root,tool.commit(),mat,at)
	node.set_meta("architecture_solid",true)
	return node

static func finish(key: String, tint: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/salvage/ancient_masonry.gdshader")
	mat.set_shader_parameter("surface_map",load(Mat.texture_path(key)))
	mat.set_shader_parameter("stone_color",tint)
	mat.set_meta("texture_key",key)
	return mat

static func glyphs(root: Node3D, at: Vector3, mat: Material, seed_value: int, rows: int = 5) -> void:
	for row in rows:
		for col in 3:
			if posmod(seed_value+row*7+col*13,5)==0: continue
			var p := at+Vector3((col-1)*.23,-row*.28,0)
			var bar := SM._box(root,Vector3(.035,.14,.025),p,mat)
			bar.rotation.z = float(posmod(seed_value+row+col,3)-1)*.55
			if (row+col)%2==0: SM._box(root,Vector3(.13,.025,.025),p+Vector3(.04,.04,.003),mat)

static func pier(root: Node3D, at: Vector3, height: float, stone: Material, trim: Material, light: Material, seed_value: int) -> void:
	block(root,Vector3(1.65,.5,1.65),at+Vector3(0,.15,0),trim)
	block(root,Vector3(1.05,height,1.05),at+Vector3(0,height*.5+.4,0),stone,.14)
	for y in [height*.35,height*.7]: block(root,Vector3(1.18,.16,1.18),at+Vector3(0,y+.4,0),trim)
	block(root,Vector3(1.5,.35,1.5),at+Vector3(0,height+.48,0),trim)
	glyphs(root,at+Vector3(0,height+.1,.54),light,seed_value,mini(6,int(height*2)))
	for side in [-1,1]:
		SM._box(root,Vector3(.045,height-.35,.025),at+Vector3(side*.39,height*.5+.48,.54),light)

static func create(seed_value: int) -> Node3D:
	var root := Node3D.new(); root.name = "VolumetricAncientRuins"
	var family := posmod(seed_value,6)
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	var key: String = Mat.ANCIENT[posmod(seed_value/6,2)]
	var stone := finish(key,[Color("bba586"),Color("a0b6af"),Color("aaa0ba")][posmod(seed_value/12,3)])
	var trim := finish("ancient-obsidian",Color("82745f"))
	var dark := finish("ancient-obsidian",Color("343b40"))
	dark.set_shader_parameter("masonry_strength",0.0)
	var light := ShaderMaterial.new()
	light.shader = preload("res://assets/salvage/ancient_energy.gdshader")
	light.set_shader_parameter("tint",[Color("72d8c9"),Color("ecb775"),Color("a5b9ec")][posmod(seed_value/3,3)])
	light.set_meta("light_source",true); light.set_meta("ancient_energy",true)
	root.set_meta("variant",family); root.set_meta("seed",seed_value); root.set_meta("surface_key",key); root.set_meta("solid_radius",15.0); root.set_meta("architecture_name",NAMES[family])
	# A buried foundation and an approach of irregular paving anchor every family.
	block(root,Vector3(20,.65,18),Vector3(0,-.22,0),trim,0)
	for i in 5:
		block(root,Vector3(3.6,.22,1.45),Vector3(.12*sin(i),-.04,10.0+i*1.5),stone)
	match family:
		0: # Open hypostyle temple, broken roof and recessed sanctuary.
			block(root,Vector3(16,.65,12),Vector3(0,.35,-1),stone)
			for side in [-1,1]:
				for i in 4:
					var h := 5.6 if i!=2 or side==-1 else 2.7
					pier(root,Vector3(side*6,.68,3.5-i*3),h,stone,trim,light,seed_value+i)
				for i in [0,2]: block(root,Vector3(1.5,.65,3.6),Vector3(side*6,6.95,2-i*3),trim)
			block(root,Vector3(12.8,.8,2.1),Vector3(0,7.0,-5.5),stone)
			block(root,Vector3(9,5,.9),Vector3(0,3.15,-6.2),stone)
			block(root,Vector3(3.4,4,.16),Vector3(0,3.2,-5.65),dark)
			glyphs(root,Vector3(0,4.5,-5.54),light,seed_value,9)
			for i in 4: block(root,Vector3(7-i*.5,.22,1.0),Vector3(0,.11+i*.16,6.8-i*.8),stone)
			block(root,Vector3(2,.7,1.7),Vector3(0,1.0,-3.8),trim)
		1: # City courtyards: tower shells, window recesses, surviving street portals.
			for side in [-1,1]:
				for i in 3:
					var x: float = side*(5.8+float(i%2)*1.0); var z := 4.0-i*5.0
					var h := rng.randf_range(3.5,8.5)
					block(root,Vector3(4.8,.6,4.6),Vector3(x,.25,z),trim)
					block(root,Vector3(4,h,1.0),Vector3(x,h*.5+.5,z-1.5),stone,.05)
					block(root,Vector3(.8,h*.72,3.8),Vector3(x+side*1.6,h*.36+.5,z),stone)
					for floor_id in int(h/1.7):
						block(root,Vector3(4.35,.18,1.2),Vector3(x,1.1+floor_id*1.7,z-1.4),trim)
						for window in 3:
							SM._box(root,Vector3(.52,.85,.035),Vector3(x+(window-1)*1.05,1.8+floor_id*1.7,z-.97),dark)
					glyphs(root,Vector3(x,h-.2,z-.96),light,seed_value+i,3)
					SM._box(root,Vector3(.045,h-.3,.025),Vector3(x+side*1.3,h*.5+.5,z-.975),light)
			for side in [-1,1]: pier(root,Vector3(side*2.1,0,-7),5.5,stone,trim,light,seed_value)
			block(root,Vector3(6.5,.8,1.9),Vector3(0,6.1,-7),stone)
		2: # Asymmetrical split monolith, planted in a stepped socket.
			for i in 3: block(root,Vector3(10-i*2,.65,8-i*1.5),Vector3(0,.15+i*.55,0),trim)
			for side in [-1,1]:
				var h := 11.5 if side==-1 else 8.6
				block(root,Vector3(2.4,h,2.8),Vector3(side*1.6,1.5+h*.5,0),dark,.38)
				glyphs(root,Vector3(side*1.6,h+.9,1.43),light,seed_value+side,18)
				block(root,Vector3(.12,h*.68,.08),Vector3(side*1.6,2.1+h*.34,1.43),light,0)
			for side in [-1,1]:
				pier(root,Vector3(side*6,0,3),2.4,stone,trim,light,seed_value+side)
		3: # Ground-supported astronomical ring on two massive pylons.
			for side in [-1,1]:
				block(root,Vector3(4,1,5),Vector3(side*4.3,.35,0),trim)
				block(root,Vector3(2.8,4.3,3),Vector3(side*4.3,2.8,0),stone,.13)
			var ring := Node3D.new(); root.add_child(ring); ring.position = Vector3(0,5.8,0)
			SM._arc(ring,5.0,1.05,1.2,0,TAU,stone)
			var engraving := Node3D.new(); ring.add_child(engraving); engraving.position.z = .615
			SM._arc(engraving,5.0,.045,.012,0,TAU,light)
			for i in 12:
				var angle := i*TAU/12
				var tick := block(ring,Vector3(.3,.6,1.35),Vector3(cos(angle)*5.0,sin(angle)*5.0,0),trim)
				tick.rotation.z = angle-PI*.5
			block(root,Vector3(2,1.6,2),Vector3(2.6,.7,3.8),stone)
			glyphs(root,Vector3(2.6,1.4,4.82),light,seed_value,4)
		4: # Terrace sanctuary with broken sentinels and central shrine.
			for i in 5: block(root,Vector3(16-i*2.4,.75,13-i*1.8),Vector3(0,.28+i*.7,-1.2),stone)
			block(root,Vector3(3,4.5,2.7),Vector3(0,5.6,-2),trim,.24)
			glyphs(root,Vector3(0,7.3,-.635),light,seed_value,12)
			for side in [-1,1]:
				pier(root,Vector3(side*6,0,5.6),4.5,stone,trim,light,seed_value)
				pier(root,Vector3(side*5.5,.8,-5.5),2.6,stone,trim,light,seed_value+1)
			for i in 9: block(root,Vector3(3.2,.2,1.1),Vector3(0,.11+i*.38,6.4-i*.95),trim)
		5: # Monumental gate, engraved lintel and rear processional colonnade.
			for side in [-1,1]:
				block(root,Vector3(4,.8,4.2),Vector3(side*4.2,.3,0),trim)
				block(root,Vector3(2.7,8.8,2.8),Vector3(side*4.2,5,0),stone,.12)
				glyphs(root,Vector3(side*4.2,8.6,1.44),light,seed_value+side,20)
				SM._box(root,Vector3(.05,7.7,.025),Vector3(side*4.2+side*.65,5,1.415),light)
				for i in 3: pier(root,Vector3(side*5.8,0,-4.5-i*2.6),3.6-i*.5,stone,trim,light,seed_value+i)
			block(root,Vector3(12,1.4,3.5),Vector3(0,9.8,0),trim)
			block(root,Vector3(9,.6,2.8),Vector3(0,10.8,0),stone)
			glyphs(root,Vector3(0,10.2,1.78),light,seed_value,3)
	# Fallen blocks lie on the soil; no random rotations that lift their corners.
	for i in 14:
		var angle := rng.randf()*TAU; var radius := rng.randf_range(11.4,15.7)
		var h := rng.randf_range(.18,.65)
		var slab := block(root,Vector3(rng.randf_range(.6,1.6),h,rng.randf_range(.5,1.4)),Vector3(cos(angle)*radius,h*.5-.08,sin(angle)*radius),stone,.12)
		slab.rotation.y = rng.randf()*TAU; slab.set_meta("ground_debris",true)
	batch(root)
	return root


static func batch(root: Node3D) -> void:
	# Static architecture is drawn in material batches, including all tiny inscriptions.
	var groups: Dictionary = {}
	var debris: Array = []
	var parts := root.find_children("*","MeshInstance3D",true,false)
	for part: MeshInstance3D in parts:
		var transform := part.transform
		var parent := part.get_parent()
		while parent!=root:
			transform = (parent as Node3D).transform*transform
			parent = parent.get_parent()
		var material := part.material_override
		if not groups.has(material):
			var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES); groups[material] = tool
		groups[material].append_from(part.mesh,0,transform)
		if part.get_meta("ground_debris",false): debris.append(transform*Vector3(0,-part.mesh.get_aabb().size.y*.5,0))
	for child in root.get_children(): child.free()
	for material: Material in groups:
		var mesh := SM._part(root,groups[material].commit(),material)
		mesh.set_meta("architecture_solid",not material.get_meta("light_source",false))
	root.set_meta("ground_contacts",debris)
