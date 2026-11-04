extends RefCounted
const Face=preload("res://scripts/face.gd")
const G=preload("res://scripts/geometry.gd")
static var meshes:Dictionary={}
static var materials:Dictionary={}
## A continuous scalp, temples and nape under the styled tufts and braids.
static func build(head: Node3D, girl: bool, color: String, highlight: String) -> MeshInstance3D:
	var key:=str(girl)+color+highlight
	if meshes.has(key):
		var cached:=G.part(head,meshes[key],Vector3.ZERO,materials[key]); cached.name="HairScalpAndNape"; cached.set_meta("hair_nape",true); return cached
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	var vertices:=PackedVector3Array(); var normals:=PackedVector3Array()
	var colors:=PackedColorArray(); var indices:=PackedInt32Array()
	for row in 33:
		for col in 97:
			var phi: float=-PI+col*TAU/96.0
			var nape:=(-0.42 if girl else -0.40)
			var lower:=lerpf(0.26,nape,smoothstep(0.6,2.0,absf(phi)))
			var theta:=row/32.0*acos(clampf(lower/0.49,-1,1))
			var p:=Face.point(theta,phi,girl)*Vector3(1.055,1.025,1.065)
			if p.y<0: p.y*=lerpf(1.0,0.49/(0.35 if girl else 0.36),smoothstep(0.6,2.0,absf(phi)))
			p.y+=0.008
			vertices.append(p)
			normals.append(Vector3(p.x/0.34,p.y/0.49,p.z/0.32).normalized())
			var strand:=pow(maxf(0,sin(phi*39.0+theta*4.0)),6)
			colors.append(Color(color).lerp(Color(highlight),0.05+strand*0.14))
			if row<32 and col<96:
				var a:=row*97+col
				indices.append_array(PackedInt32Array([a,a+98,a+97,a,a+1,a+98]))
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var mat:=StandardMaterial3D.new(); mat.vertex_color_use_as_albedo=true; mat.vertex_color_is_srgb=true
	mat.roughness=0.72; mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	meshes[key]=mesh; materials[key]=mat
	var node:=G.part(head,mesh,Vector3.ZERO,mat); node.name="HairScalpAndNape"
	node.set_meta("hair_nape",true)
	return node
