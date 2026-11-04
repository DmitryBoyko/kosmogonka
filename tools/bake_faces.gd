extends SceneTree
func _initialize(): call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute("res://assets/hero_cache")
 var face=load("res://scripts/face.gd"); face.baking=true
 for girl in [false,true]:
  var head:=Node3D.new();root.add_child(head);face.build(head,girl)
  var key:=str(girl)+"true"
  print("BAKE FACE ",ResourceSaver.save(face.templates[key],"res://assets/hero_cache/face_"+("girl" if girl else "boy")+".scn",ResourceSaver.FLAG_COMPRESS))
  head.free()
 quit()
