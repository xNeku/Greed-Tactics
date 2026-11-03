extends SceneTree
## Exports every roster hero and every zone enemy (stats, skills, rage
## mutations and sprites as palette + rows) to JSON: {heroes: [], enemies: []},
## the documents of Neku's hero workshop artifact (tools/hero_workshop/).
## Usage: godot --headless --script res://tools/export_hero_sheets.gd -- out.json

const SLOT_NAMES := ["Básica", "Lanzamiento", "Área", "Movimiento"]
const RESOURCE_NAMES := ["Enfriamientos", "Maná", "Ira"]
const SYMBOLS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const BEHAVIOURS := {
	"melee_aggressive": "Cuerpo a cuerpo agresivo: va a por ti sin miedo",
	"skirmisher": "Hostigador: entra, golpea y se aparta",
	"ranged": "A distancia: mantiene 4 casillas",
	"boss": "Jefe: casi ignora el peligro y concentra el daño",
}


func _initialize() -> void:
	var out_path := OS.get_cmdline_user_args()[0]
	var config := load("res://content/run/default_run.tres") as RunConfig
	var heroes: Array = []
	for i in config.roster.size():
		var sheet := _hero(config.roster[i])
		sheet["order"] = i
		heroes.append(sheet)
	var enemies: Array = []
	var seen: Dictionary = {}
	for zone in config.zones:
		for pool: Array[UnitData] in [zone.enemy_pool, zone.miniboss_pool]:
			for data in pool:
				if not seen.has(data):
					seen[data] = _enemy(data, pool == zone.miniboss_pool)
					seen[data]["order"] = seen.size()
					enemies.append(seen[data])
				var zones: Array = seen[data]["zones"]
				if not zones.has(zone.display_name):
					zones.append(zone.display_name)
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"heroes": heroes, "enemies": enemies}, "  "))
	print("Exported %d heroes and %d enemies to %s" % [heroes.size(), enemies.size(), out_path])
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


func _enemy(data: UnitData, miniboss: bool) -> Dictionary:
	var skills: Array = []
	for skill in data.skills:
		skills.append(_skill(skill))
	var profile := data.ai_profile.resource_path.get_file().get_basename() if data.ai_profile != null else ""
	return {
		"id": String(data.id),
		"name": data.display_name,
		"category": "miniboss" if miniboss else "normal",
		"zones": [],
		"race": data.race,
		"heroClass": data.unit_class,
		"description": data.description,
		"behaviour": BEHAVIOURS.get(profile, profile),
		"scale": data.sprite_scale,
		"rewards": {"xp": data.xp_reward, "gold": data.gold_reward},
		"stats": {"hp": data.max_hp, "mp": data.max_mp, "attack": data.attack, "defense": data.defense,
			"speed": data.speed, "move": data.move_points, "evasion": data.evasion, "crit": data.crit_chance},
		"skills": skills,
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
