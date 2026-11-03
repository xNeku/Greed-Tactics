extends SceneTree
## Exports every roster hero (stats, skills, rage mutations and sprites as
## palette + rows) to JSON, the format of Neku's sprite editor artifact.
## Usage: godot --headless --script res://tools/export_hero_sheets.gd -- out.json

const SLOT_NAMES := ["Básica", "Lanzamiento", "Área", "Movimiento"]
const RESOURCE_NAMES := ["Enfriamientos", "Maná", "Ira"]
const SYMBOLS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


func _initialize() -> void:
	var out_path := OS.get_cmdline_user_args()[0]
	var config := load("res://content/run/default_run.tres") as RunConfig
	var heroes: Array = []
	for data in config.roster:
		heroes.append(_hero(data))
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(heroes, "  "))
	print("Exported %d heroes to %s" % [heroes.size(), out_path])
	quit()


func _hero(data: UnitData) -> Dictionary:
	var skills: Array = []
	var unlocks: Array = []
	for skill in data.skills:
		skills.append(_skill(skill))
		if skill.empowered_variant != null:
			var unlock := _skill(skill.empowered_variant)
			unlock["requirement"] = "%d de ira (muta %s)" % [skill.empowered_rage_threshold, skill.display_name]
			unlocks.append(unlock)
	return {
		"id": String(data.id),
		"name": data.display_name,
		"race": data.race,
		"heroClass": data.unit_class,
		"resource": RESOURCE_NAMES[data.resource_kind],
		"description": data.description,
		"stats": {"hp": data.max_hp, "mp": data.max_mp, "attack": data.attack, "defense": data.defense,
			"speed": data.speed, "move": data.move_points, "evasion": data.evasion, "crit": data.crit_chance},
		"skills": skills,
		"unlocks": unlocks,
		"sprites": {"front": _sprite(data.sprite), "side": _sprite(data.sprite_side)},
	}


func _skill(skill: SkillData) -> Dictionary:
	var cost := PackedStringArray()
	if skill.mp_cost > 0:
		cost.append("%d maná" % skill.mp_cost)
	if skill.rage_cost > 0:
		cost.append("%d ira" % skill.rage_cost)
	if skill.cooldown > 0:
		cost.append("enfriamiento %d" % skill.cooldown)
	return {"id": String(skill.id), "slot": SLOT_NAMES[skill.skill_type], "name": skill.display_name,
		"description": skill.description, "cost": ", ".join(cost) if not cost.is_empty() else "gratis"}


## {w, h, palette: ["#rrggbb"], rows: ["..ab.."]} ('.' = transparent).
func _sprite(texture: Texture2D) -> Variant:
	if texture == null:
		return null
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	var palette: Array[String] = []
	var rows: Array[String] = []
	for y in image.get_height():
		var row := ""
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				row += "."
				continue
			var hex := "#" + color.to_html(false)
			var index := palette.find(hex)
			if index == -1:
				palette.append(hex)
				index = palette.size() - 1
			row += SYMBOLS[index]
		rows.append(row)
	return {"w": image.get_width(), "h": image.get_height(), "palette": palette, "rows": rows}
