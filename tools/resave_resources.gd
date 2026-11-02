extends SceneTree
## Re-saves every .tscn/.tres through Godot so files use the exact editor
## format (UIDs included). Run after editing scenes/resources as text:
##   godot --headless --script res://tools/resave_resources.gd

const ROOTS: PackedStringArray = ["res://assets", "res://content", "res://scenes"]


func _initialize() -> void:
	var count := 0
	for root_dir in ROOTS:
		for path in _collect(root_dir):
			var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if resource == null:
				push_error("Could not load %s" % path)
				continue
			var error := ResourceSaver.save(resource, path)
			if error != OK:
				push_error("Could not save %s (%s)" % [path, error_string(error)])
			else:
				count += 1
	print("Re-saved %d resources." % count)
	quit()


func _collect(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tscn") or file.ends_with(".tres"):
			result.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		result.append_array(_collect(dir_path.path_join(sub)))
	return result
