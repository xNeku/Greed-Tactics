class_name UiKit
extends RefCounted
## Small builders shared by the menus (theme variations from ui_theme.tres).


## A rounded tag: "◆ Vista de águila". Gold for highlights.
static func chip(text: String, gold := false, tooltip := "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ChipGold" if gold else &"Chip"
	panel.tooltip_text = tooltip
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 13)
	panel.add_child(label)
	return panel


static func caption(text: String, wrap := true) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"CaptionLabel"
	label.text = text
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func header(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"HeaderLabel"
	label.text = text
	return label


## "Etiqueta   valor" row for stat tables.
static func stat_row(name: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var left := caption(name, false)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := Label.new()
	right.text = value
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(left)
	row.add_child(right)
	return row


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
