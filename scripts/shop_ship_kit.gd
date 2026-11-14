extends RefCounted
const ROOT="res://assets/shop_ship/"
const G=preload("res://scripts/geometry.gd")
static var scenes:Dictionary={}
static var materials:Dictionary={}
static func model(parent:Node3D,id:String,at:Vector3,size:Vector3,yaw:float=0.) -> Node3D:
	if not scenes.has(id): scenes[id]=load(ROOT+"models/"+id+".gltf")
	var asset:Node3D=scenes[id].instantiate(); var holder:=Node3D.new(); parent.add_child(holder); holder.add_child(asset)
	var bounds:=AABB(); var first:=true
	for piece:MeshInstance3D in asset.find_children("*","MeshInstance3D",true,false):
		var transform:=piece.transform; var owner_node:=piece.get_parent()
		while owner_node!=asset: transform=(owner_node as Node3D).transform*transform; owner_node=owner_node.get_parent()
		var box:AABB=transform*piece.mesh.get_aabb(); bounds=box if first else bounds.merge(box); first=false
		for surface in piece.mesh.get_surface_count():
			var original:=piece.get_active_material(surface) as StandardMaterial3D
			if original==null: continue
			var key:=str(original.get_instance_id())
			if not materials.has(key):
				var copy:=original.duplicate() as StandardMaterial3D
				copy.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if original.resource_name.contains("Trim_01"):
					copy.emission_enabled=true; copy.emission=Color("9cdded"); copy.emission_operator=BaseMaterial3D.EMISSION_OP_MULTIPLY
					copy.emission_texture=preload("res://assets/shop_ship/textures/T_Trim_01_Emissive.png"); copy.emission_energy_multiplier=.7
				copy.roughness=maxf(.35,copy.roughness); materials[key]=copy
			piece.set_surface_override_material(surface,materials[key])
		piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.set_meta("architecture_solid",true)
	var scale_value:Vector3=size/bounds.size
	asset.scale=scale_value; asset.position=-(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5))*scale_value
	holder.position=at; holder.rotation.y=yaw; holder.set_meta("source_model",id); return holder
static func terminal(category:String,index:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="ShipComputer_"+category
	model(root,"Platform_CenterPlate",Vector3(0,0,0),Vector3(3.8,.16,3.2))
	model(root,"Prop_Computer",Vector3(0,.16,.20),Vector3(1.45,2.25,1.1))
	for side in [-1,1]:
		model(root,"Column_MetalSupport",Vector3(side*1.43,.16,-.55),Vector3(.35,2.60,.42))
		model(root,"Prop_Light_Floor",Vector3(side*1.35,.18,1.10),Vector3(.32,.14,.55))
	var color:String=["6dded7","c1a1ff","ffd18a"][index%3]
	for side in [-1,1]: G.box(root,Vector3(.045,2.18,.04),Vector3(side*1.22,1.25,-.28),color,.45)
	var name_label:=G.label(root,{"suit":"СКАФАНДРЫ","pack":"РАНЦЫ","board":"ПЛАТФОРМЫ"}[category],Vector3(0,2.95,.05),30)
	name_label.pixel_size=.0045
	var status_label:=G.label(root,"ПРИМЕРОЧНАЯ / КАТАЛОГ",Vector3(0,2.65,.06),19); status_label.pixel_size=.0038; status_label.modulate=Color(color)
	root.set_meta("ship_interior_source","spacetamagoshi / Quaternius Modular SciFi MegaKit")
	G.merge_static(root); return root
