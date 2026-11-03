extends SceneTree
## Builds a SpriteFrames resource from a sprite sheet + its JSON layout:
##   {"cell": [w, h], "animations": [{"name", "row", "frames", "fps", "loop"}]}
## Each animation is one row of the sheet, frames left to right.
## Usage:
##   godot --headless --script res://tools/build_sprite_frames.gd -- \
##       res://assets/sprites/units/kael_sheet.png res://content/units/heroes/kael_frames.tres


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -- <sheet.png> <output.tres>")
		quit(1)
		return
	var sheet_path := args[0]
	var output_path := args[1]
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sheet_path.get_basename() + ".json"))
	var sheet: Texture2D = load(sheet_path)
	var cell := Vector2(layout.cell[0], layout.cell[1])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: Dictionary in layout.animations:
		var name := StringName(anim.name)
		frames.add_animation(name)
		frames.set_animation_speed(name, anim.fps)
		frames.set_animation_loop(name, anim.loop)
		for i in int(anim.frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(Vector2(i * cell.x, anim.row * cell.y), cell)
			frames.add_frame(name, atlas)
	var error := ResourceSaver.save(frames, output_path)
	print("Saved %s (%d animations): %s" % [output_path, layout.animations.size(), error_string(error)])
	quit(0 if error == OK else 1)
