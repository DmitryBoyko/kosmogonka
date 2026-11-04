extends Node
## Detach immediately; release small pieces between frames instead of a mass free.
var pending:Array[Node]=[]
func retire(node:Node) -> void:
	if not is_instance_valid(node): return
	if node is Node3D: node.hide()
	if node.get_parent(): node.get_parent().remove_child(node)
	pending.append(node)
func _process(_dt:float) -> void:
	var deadline:int=Time.get_ticks_usec()+1200
	while not pending.is_empty() and Time.get_ticks_usec()<deadline:
		var node:Node=pending[-1]
		if not is_instance_valid(node): pending.pop_back(); continue
		if node.get_child_count():
			var child:=node.get_child(node.get_child_count()-1); node.remove_child(child); pending.append(child)
		else: pending.pop_back(); node.free()
func _exit_tree() -> void:
	for node in pending:
		if is_instance_valid(node): node.free()
	pending.clear()
