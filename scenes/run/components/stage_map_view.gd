class_name StageMapView
extends Control
## Draws one stage of the RunMap: columns of node buttons (left to right) and
## the paths between them. Visited path in gold, next choices clickable.

signal node_chosen(node: RunMap.MapNode)

const KIND_NAMES := ["Combate", "Élite", "Reclutar", "Descanso", "Miniboss"]
const KIND_HINTS := [
	"Oro y XP.",
	"Más enemigos y más fuertes: modificador para tu protagonista.",
	"Un héroe se ofrece a unirse al grupo.",
	"El grupo recupera vida.",
	"El jefe de la zona: modificador y, si cabe, un nuevo compañero.",
]
const KIND_COLORS := [
	Color(0.86, 0.89, 1.0), Color(1.0, 0.5, 0.45), Color(0.5, 1.0, 0.6),
	Color(0.55, 0.8, 1.0), Color(1.0, 0.72, 0.3),
]
const OBJECTIVE_NAMES := ["", "Proteger la carreta", "Escapar"]
const LINE_COLOR := Color(0.35, 0.4, 0.55, 0.6)
const PATH_COLOR := Color(1.0, 0.8, 0.35)
const CHOICE_COLOR := Color(0.8, 0.9, 1.0, 0.9)
const NODE_SIZE := Vector2(184, 64)

var _run: RunState
var _buttons: Dictionary = {}  # MapNode -> Button


func show_map(run: RunState) -> void:
	_run = run
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	var map := run.get_map()
	var choices := run.get_choices()
	for layer in map.get_layer_count():
		for node: RunMap.MapNode in map.get_layer(layer):
			var button := _make_button(node, choices.has(node))
			add_child(button)
			_buttons[node] = button
	_layout()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _run != null:
		_layout()
		queue_redraw()


func _make_button(node: RunMap.MapNode, is_choice: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = NODE_SIZE
	button.size = NODE_SIZE
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	var text: String = KIND_NAMES[node.kind]
	if node.objective != RunMap.Objective.NONE:
		text += "\n" + OBJECTIVE_NAMES[node.objective]
	button.text = text
	button.tooltip_text = KIND_HINTS[node.kind] + (
		"\nObjetivo opcional: %s (premio: modificador + oro)." % OBJECTIVE_NAMES[node.objective].to_lower()
		if node.objective != RunMap.Objective.NONE else "")
	var color: Color = KIND_COLORS[node.kind]
	button.add_theme_color_override(&"font_color", color)
	button.add_theme_color_override(&"font_hover_color", color.lightened(0.3))
	button.add_theme_color_override(&"font_disabled_color", color.darkened(0.55) if not node.visited else color.darkened(0.15))
	button.disabled = not is_choice
	if is_choice:
		button.pressed.connect(func() -> void: node_chosen.emit(node))
	return button


## Columns spread over the width, nodes centred vertically in each column.
func _layout() -> void:
	var map := _run.get_map()
	var columns := map.get_layer_count()
	var step_x := (size.x - NODE_SIZE.x) / maxf(columns - 1, 1)
	for layer in columns:
		var row: Array = map.get_layer(layer)
		var step_y := minf(NODE_SIZE.y * 1.9, (size.y - NODE_SIZE.y) / maxf(row.size() - 1, 1))
		var top := (size.y - NODE_SIZE.y - step_y * (row.size() - 1)) / 2.0
		for node: RunMap.MapNode in row:
			var button: Button = _buttons.get(node)
			if button != null:
				button.position = Vector2(layer * step_x, top + node.index * step_y)


func _draw() -> void:
	if _run == null:
		return
	var map := _run.get_map()
	var choices := _run.get_choices()
	for layer in map.get_layer_count() - 1:
		for node: RunMap.MapNode in map.get_layer(layer):
			for index in node.links:
				var next: RunMap.MapNode = map.get_layer(layer + 1)[index]
				var color := LINE_COLOR
				var width := 2.0
				if node.visited and next.visited:
					color = PATH_COLOR
					width = 4.0
				elif node == _run.current_node and choices.has(next):
					color = CHOICE_COLOR
					width = 3.0
				draw_line(_anchor(node, true), _anchor(next, false), color, width, true)
	var current := _run.current_node
	if current != null and _buttons.has(current):
		var rect := Rect2(_buttons[current].position - Vector2(4, 4), NODE_SIZE + Vector2(8, 8))
		draw_rect(rect, PATH_COLOR, false, 3.0)
	if current == null:
		for node in choices:
			draw_circle(_anchor(node, false) - Vector2(14, 0), 6.0, CHOICE_COLOR)


func _anchor(node: RunMap.MapNode, right: bool) -> Vector2:
	var button: Button = _buttons.get(node)
	if button == null:
		return Vector2.ZERO
	return button.position + Vector2(NODE_SIZE.x if right else 0.0, NODE_SIZE.y / 2.0)
