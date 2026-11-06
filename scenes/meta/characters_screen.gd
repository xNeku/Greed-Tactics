extends Control
## Characters and progression (v0.10): every hero with its account level
## (I-X), XP, the progression line (what each level unlocks, the boss walls at
## V and X), the weapons it can carry and its run stats. Saved profile.

const STATE_UNLOCKED := Color(1.0, 0.85, 0.45)

@onready var _hero_list: VBoxContainer = %HeroList
@onready var _global_stats: Label = %GlobalStats
@onready var _back_button: Button = %BackButton
@onready var _portrait: TextureRect = %Portrait
@onready var _hero_name: Label = %HeroName
@onready var _hero_class: Label = %HeroClass
@onready var _roman: Label = %Roman
@onready var _level_state: Label = %LevelState
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_label: Label = %XpLabel
@onready var _track: GridContainer = %Track
@onready var _weapons: HFlowContainer = %Weapons
@onready var _stats: GridContainer = %Stats

var _game: GameSession
var _selected: UnitData
var _buttons: Dictionary[UnitData, Button] = {}


func _ready() -> void:
	_game = get_node(^"/root/Game") as GameSession
	_back_button.pressed.connect(_game.go_to_main_menu)
	var profile := _game.profile
	var rate := 100.0 * profile.total_wins / maxf(profile.total_runs, 1)
	_global_stats.text = "Runs %d · Victorias %d (%d%%) · Enemigos %d · Jefes %d · Turnos %d" % [
		profile.total_runs, profile.total_wins, roundi(rate), profile.total_enemies, profile.total_bosses, profile.total_turns]
	var roster := _game.run_config.roster
	for hero in roster:
		var button := Button.new()
		button.toggle_mode = true
		button.icon = hero.sprite
		button.expand_icon = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s   %s" % [hero.display_name, ProgressionConfig.roman(profile.get_level(_game.progression, hero.id))]
		button.add_theme_constant_override(&"icon_max_width", 32)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.pressed.connect(_select.bind(hero))
		_hero_list.add_child(button)
		_buttons[hero] = button
	_select(roster[0])


func _select(hero: UnitData) -> void:
	_selected = hero
	for data in _buttons:
		_buttons[data].set_pressed_no_signal(data == hero)
	var config := _game.progression
	var profile := _game.profile
	var level := profile.get_level(config, hero.id)
	var record := profile.get_record(hero.id)
	_portrait.texture = hero.sprite
	_hero_name.text = hero.display_name
	_hero_class.text = "%s %s · %s" % [hero.unit_class, hero.race, hero.description]
	_hero_class.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roman.text = ProgressionConfig.roman(level)
	if level >= ProgressionConfig.MAX_LEVEL:
		_xp_bar.value = 100.0
		_xp_label.text = "%d XP en total" % record.xp
		_level_state.text = "Maestría ★" if profile.is_master(config, hero.id) else "Nivel máximo. Para la maestría: vence a %s." % config.gate_boss_names(10)
	else:
		var from := config.level_xp[level - 1]
		var to := config.level_xp[level]
		_xp_bar.value = 100.0 * (record.xp - from) / maxf(to - from, 1)
		_xp_label.text = "%d / %d XP hasta el nivel %s · %d XP en total" % [record.xp - from, to - from, ProgressionConfig.roman(level + 1), record.xp]
		_level_state.text = "Bloqueado en el V: vence a %s con %s para seguir." % [config.gate_boss_names(5), hero.display_name] \
			if profile.get_wall(config, hero.id) > 0 else "Nivel de cuenta"
	_build_track(hero, level)
	_build_weapons(hero, level)
	_build_stats(hero)


## Cards I..X: unlocked in gold, the next one outlined, the rest dim; the
## walls at V and X name the bosses that open them.
func _build_track(hero: UnitData, level: int) -> void:
	UiKit.clear(_track)
	var config := _game.progression
	var track := config.get_track(hero.id)
	for step in range(1, ProgressionConfig.MAX_LEVEL + 1):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(150, 0)
		card.theme_type_variation = &"SelectedCard" if step <= level else (&"Card" if step == level + 1 else &"CardLocked")
		var box := VBoxContainer.new()
		box.add_theme_constant_override(&"separation", 2)
		card.add_child(box)
		var roman := Label.new()
		roman.theme_type_variation = &"RomanLevel"
		roman.add_theme_font_size_override(&"font_size", 24)
		roman.text = ProgressionConfig.roman(step)
		if step > level:
			roman.modulate = Color(1, 1, 1, 0.45)
		box.add_child(roman)
		var rewards := track.get_rewards_at(step) if track != null else []
		if step == 1:
			box.add_child(UiKit.caption("Inicio: %s tal cual." % hero.display_name))
		for reward in rewards:
			var line := UiKit.caption(reward.describe())
			if step <= level:
				line.add_theme_color_override(&"font_color", STATE_UNLOCKED)
			box.add_child(line)
		if step == 5 or step == 10:
			var gate := UiKit.caption("Muro: vence a %s para %s." % [config.gate_boss_names(step),
				"pasar del V" if step == 5 else "la maestría"])
			gate.theme_type_variation = &"LockedLabel"
			box.add_child(gate)
		_track.add_child(card)


## The hero's own weapon plus the unlocked ones (click to equip). Locked ones
## show the level that opens them.
func _build_weapons(hero: UnitData, level: int) -> void:
	UiKit.clear(_weapons)
	var config := _game.progression
	var record := _game.profile.get_record(hero.id)
	var options: Array = [[hero.weapon, "", 1]]
	var track := config.get_track(hero.id)
	if track != null:
		for reward in track.rewards:
			if reward.kind == ProgressionReward.Kind.WEAPON and reward.weapon != null:
				options.append([reward.weapon, String(reward.weapon.id), reward.level])
	for option in options:
		var weapon: WeaponData = option[0]
		var key: String = option[1]
		var needed: int = option[2]
		var button := Button.new()
		button.toggle_mode = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.icon = weapon.sprite if weapon != null else null
		button.add_theme_constant_override(&"icon_max_width", 40)
		var name := weapon.display_name if weapon != null else "Sin arma"
		button.text = name if needed <= level else "%s (nivel %s)" % [name, ProgressionConfig.roman(needed)]
		button.disabled = needed > level
		button.set_pressed_no_signal(record.weapon == key)
		button.pressed.connect(_equip.bind(hero, key))
		_weapons.add_child(button)
	if options.size() == 1:
		_weapons.add_child(UiKit.caption("Más armas para %s: próximamente (botín y desbloqueos)." % hero.display_name))


func _equip(hero: UnitData, key: String) -> void:
	_game.profile.get_record(hero.id).weapon = key
	_game.save_profile()
	_select(hero)


func _build_stats(hero: UnitData) -> void:
	UiKit.clear(_stats)
	var record := _game.profile.get_record(hero.id)
	var rate := 100.0 * record.wins / maxf(record.runs, 1)
	var bosses: PackedStringArray = []
	for id in record.bosses:
		bosses.append(_boss_name(id))
	for pair in [
		["Runs como protagonista", str(record.runs)],
		["Victorias", "%d (%d%%)" % [record.wins, roundi(rate)]],
		["Mejor etapa", str(record.best_stage) if record.best_stage > 0 else "-"],
		["Combates ganados", str(record.battles)],
		["Enemigos vencidos", str(record.enemies)],
		["Turnos jugados", str(record.turns)],
		["Jefes vencidos", ", ".join(bosses) if not bosses.is_empty() else "ninguno"],
	]:
		var name := UiKit.caption(pair[0], false)
		var value := Label.new()
		value.text = pair[1]
		_stats.add_child(name)
		_stats.add_child(value)


func _boss_name(id: String) -> String:
	for zone in _game.run_config.zones:
		for boss in zone.miniboss_pool:
			if String(boss.id) == id:
				return boss.display_name
	return id
