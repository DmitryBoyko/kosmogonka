extends SceneTree
func _initialize():call_deferred("run")
func own(node: Node, owner_node: Node):
 for child in node.get_children():child.owner=owner_node;own(child,owner_node)
func run():
 DirAccess.make_dir_recursive_absolute("res://build/cache-originals-01626")
 for world in 11:
  var path="res://assets/planet_cache/finish_%d.scn"%world
  var backup="res://build/cache-originals-01626/finish_%d.scn"%world
  if not FileAccess.file_exists(backup):DirAccess.copy_absolute(path,backup)
  var node=load(path).instantiate()
  var city=node.get_node("FinishCity")
  for child in city.get_children():child.free()
  for key in city.get_meta_list():city.remove_meta(key)
  for key in ["city_collision_boxes","cached_collision_shapes"]:
   if node.has_meta(key):node.remove_meta(key)
  own(node,node)
  var scene=PackedScene.new();assert(scene.pack(node)==OK)
  assert(ResourceSaver.save(scene,path,ResourceSaver.FLAG_COMPRESS)==OK)
  node.free()
 print("Removed retired city geometry and cached collision duplicates from 11 finishes")
 quit()
