extends Control
## End of a run (v0.10), won or lost: the run in numbers, and what it gave the
## protagonist's account. The XP bar fills up level by level (Roman numerals),
## new unlocks appear one by one, and a wall (boss needed) is announced.

const FILL_TIME := 0.9

@onready var _title_label: Label = %TitleLabel
@onready var _run_chips: HFlowContainer = %RunChips
@onready var _portrait: TextureRect = %Portrait
@onready var _hero_name: Label = %HeroName
@onready var _roman: Label = %Roman
@onready var _level_up: Label = %LevelUp
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_label: Label = %XpLabel
@onready var _breakdown: VBoxContainer = %Breakdown
@onready var _wall_label: Label = %WallLabel
@onready var _unlocks: VBoxContainer = %Unlocks
@onready var _party_label: Label = %PartyLabel
@onready var _menu_button: Button = %MenuButton
@onready var _characters_button: Button = %CharactersButton

var _game: GameSession


func _ready() -> void:
	_game = get_node(^"/root/Game") as GameSession
	_menu_button.pressed.connect(_game.abandon_run)
	_characters_button.pressed.connect(func() -> void:
		_game.run = null
		_game.open_characters())
	var run := _game.run
	if run == null:
		_game.go_to_main_menu()
		return
	var won := run.status == RunState.Status.WON
	_title_label.text = "¡Run completada!" if won else "Derrota"
	for text in ["Etapa %d/%d" % [run.stage + 1, run.config.stage_count], "%d combates ganados" % run.battles_won,
			"%d enemigos" % run.enemies_defeated, "%d jefes" % run.bosses_defeated.size(), "%d turnos" % run.total_turns,
			"%d oro" % run.gold, "Semilla %d" % run.seed_value]:
		_run_chips.add_child(UiKit.chip(text))
	var names := run.heroes.map(func(h: HeroState) -> String: return h.data.display_name)
	var mods := run.modifiers.map(func(m: ModifierData) -> String: return m.display_name)
	_party_label.text = "%s\nModificadores: %s" % [", ".join(names), ", ".join(mods) if not mods.is_empty() else "ninguno"]
	_portrait.texture = run.get_protagonist().data.sprite
	_hero_name.text = run.get_protagonist().data.display_name
	_level_up.modulate.a = 0.0
	_wall_label.visible = false
	var report := _game.last_report
	if report == null:
		_xp_label.text = ""
		return
	for line in report.breakdown:
		_breakdown.add_child(UiKit.caption("· " + line, false))
	_animate(report)


## Fills the bar from the old XP to the new one, level by level.
func _animate(report: RunReport) -> void:
	var config := _game.progression
	_roman.text = ProgressionConfig.roman(report.level_before)
	_xp_label.text = "+%d XP" % report.xp_gained
	_set_bar(config, report.level_before, report.xp_before)
	await get_tree().create_timer(0.4).timeout
	var xp := report.xp_before
	var level := report.level_before
	while true:
		var top := config.level_xp[level] if level < ProgressionConfig.MAX_LEVEL else report.xp_after
		var target := mini(report.xp_after, top)
		var tween := create_tween()
		tween.tween_method(func(v: float) -> void: _set_bar(config, level, roundi(v)), float(xp), float(target), FILL_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
		xp = target
		if level < report.level_after and xp >= top:
			level += 1
			_level_up_flash(level)
			await get_tree().create_timer(0.5).timeout
		else:
			break
	for reward in report.unlocks:
		_add_unlock(reward)
		await get_tree().create_timer(0.25).timeout
	if report.unlocks.is_empty():
		_unlocks.add_child(UiKit.caption("Nada nuevo esta vez. Sigue jugando con %s." % _hero_name.text))
	if report.wall > 0:
		_wall_label.visible = true
		_wall_label.text = "Bloqueado en el nivel V: vence a %s con %s para seguir subiendo (la XP espera)." % [
			config.gate_boss_names(5), _hero_name.text]
	elif report.wall_broken:
		_add_banner("¡Muro roto! Ya puedes pasar del nivel V.")
	if report.became_master:
		_add_banner("¡Maestría! %s es Maestro ★" % _hero_name.text)


func _set_bar(config: ProgressionConfig, level: int, xp: int) -> void:
	if level >= ProgressionConfig.MAX_LEVEL:
		_xp_bar.value = 100.0
		return
	var from := config.level_xp[level - 1]
	var to := config.level_xp[level]
	_xp_bar.value = 100.0 * (xp - from) / maxf(to - from, 1)


func _level_up_flash(level: int) -> void:
	_roman.text = ProgressionConfig.roman(level)
	_level_up.text = "¡Nivel %s!" % ProgressionConfig.roman(level)
	_roman.pivot_offset = _roman.size * 0.5
	var tween := create_tween().set_parallel()
	_roman.scale = Vector2.ONE * 1.6
	tween.tween_property(_roman, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_level_up.modulate.a = 1.0
	_roman.modulate = Color(2.0, 1.8, 1.2)
	tween.tween_property(_roman, "modulate", Color.WHITE, 0.5)


func _add_unlock(reward: ProgressionReward) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	var roman := Label.new()
	roman.theme_type_variation = &"RomanLevel"
	roman.add_theme_font_size_override(&"font_size", 22)
	roman.text = ProgressionConfig.roman(reward.level)
	roman.custom_minimum_size = Vector2(56, 0)
	row.add_child(roman)
	row.add_child(UiKit.chip(reward.describe(), reward.kind != ProgressionReward.Kind.STATS,
		reward.modifier.description if reward.modifier != null else ""))
	row.modulate.a = 0.0
	_unlocks.add_child(row)
	create_tween().tween_property(row, "modulate:a", 1.0, 0.3)


func _add_banner(text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = &"GoldLabel"
	label.add_theme_font_size_override(&"font_size", 20)
	label.text = text
	_unlocks.add_child(label)
