class_name PreviewCard
extends PanelContainer
## Floating forecast over a target (GDD §3, "lo que ves es lo que pasa"):
## side, damage, resulting HP, hit/crit chances, statuses, push and bounces.

const LETHAL_COLOR := Color(1.0, 0.45, 0.4)
const BACK_COLOR := Color(1.0, 0.8, 0.3)
const EXTRA_COLOR := Color(1.0, 0.7, 0.35)

@onready var _title_label: Label = %TitleLabel
@onready var _damage_label: Label = %DamageLabel
@onready var _chance_label: Label = %ChanceLabel
@onready var _status_label: Label = %StatusLabel
@onready var _extra_label: Label = %ExtraLabel


func show_preview(preview: AttackPreview) -> void:
	var target := preview.target
	_title_label.text = "%s • %s" % [target.display_name, preview.get_side_name()]
	_title_label.modulate = BACK_COLOR if preview.side == GridRules.AttackSide.BACK else Color.WHITE
	var lethal := preview.get_total_damage() >= target.hp
	var per_strike := "×%d" % preview.strikes if preview.strikes > 1 else ""
	_damage_label.text = "Daño %d%s (crít %d) · HP %d → %d%s" % [
		preview.damage, per_strike, preview.crit_damage, target.hp, preview.get_hp_after(), "  ¡LETAL!" if lethal else ""]
	_damage_label.modulate = LETHAL_COLOR if lethal else Color.WHITE
	_chance_label.text = "Golpe %d%%   Crít %d%%" % [preview.hit_chance, preview.crit_chance]

	var statuses := PackedStringArray()
	for app in preview.statuses:
		var text := "%s %d%%" % [app.status.display_name, app.chance]
		if app.status.max_stacks > 1:
			var now := target.get_stacks(app.status)
			var after := mini(now + preview.strikes, app.status.max_stacks)
			text += " (cargas %d → %d)" % [now, after]
		statuses.append(text)
	_status_label.visible = not statuses.is_empty()
	_status_label.text = " · ".join(statuses)
	if not preview.statuses.is_empty():
		_status_label.modulate = preview.statuses[0].status.color

	var extra := PackedStringArray()
	if preview.knockback > 0:
		var cut := preview.push_blocked_at != CombatState.NO_CELL
		extra.append("Empuje %d%s" % [preview.knockback, " → se corta" if cut else ""])
	if preview.bounces > 0:
		extra.append("Rebota ×%d" % preview.bounces)
	_extra_label.visible = not extra.is_empty()
	_extra_label.text = " · ".join(extra)
	_extra_label.modulate = EXTRA_COLOR
