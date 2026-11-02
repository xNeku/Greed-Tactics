class_name PreviewCard
extends PanelContainer
## Floating forecast over a target: side, damage, hit and crit (GDD §3).

const LETHAL_COLOR := Color(1.0, 0.45, 0.4)
const BACK_COLOR := Color(1.0, 0.8, 0.3)

@onready var _title_label: Label = %TitleLabel
@onready var _damage_label: Label = %DamageLabel
@onready var _chance_label: Label = %ChanceLabel


func show_preview(preview: AttackPreview) -> void:
	_title_label.text = "%s • %s" % [preview.target.display_name, preview.get_side_name()]
	_title_label.modulate = BACK_COLOR if preview.side == GridRules.AttackSide.BACK else Color.WHITE
	var lethal := preview.damage >= preview.target.hp
	_damage_label.text = "Daño: %d%s" % [preview.damage, "  (letal)" if lethal else ""]
	_damage_label.modulate = LETHAL_COLOR if lethal else Color.WHITE
	_chance_label.text = "Golpe: %d%%   Crít: %d%%" % [preview.hit_chance, preview.crit_chance]
