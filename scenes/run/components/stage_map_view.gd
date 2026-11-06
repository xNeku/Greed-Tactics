class_name StageMapView
extends Control
## Draws one stage of the RunMap (v0.10): medallions with a drawn icon per
## kind (crossed swords, elite skull, recruit, campfire, boss crown), the
## paths between them (walked path in gold, next choices bright), and the
## choices pulsing. Clicks on a choice emit [signal node_chosen]; hovering any
## node emits [signal node_hovered] (null when the mouse leaves).

signal node_chosen(node: RunMap.MapNode)
signal node_hovered(node: RunMap.MapNode)

const KIND_NAMES := ["Combate", "Élite", "Reclutar", "Descanso", "Miniboss"]
const KIND_HINTS := [
	"Oro y XP.",
	"Más enemigos, uno de ellos élite (aura violeta): modificador para tu protagonista.",
	"Un héroe se ofrece a unirse al grupo.",
	"El grupo recupera vida.",
	"El jefe de la zona en su estrado: modificador y, si cabe, un nuevo compañero.",
]
const KIND_COLORS := [
	Color(0.86, 0.88, 0.95), Color(0.85, 0.45, 1.0), Color(0.5, 1.0, 0.6),
	Color(0.55, 0.8, 1.0), Color(1.0, 0.62, 0.25),
]
const OBJECTIVE_NAMES := ["", "Proteger la carreta", "Escapar"]
const LINE_COLOR := Color(0.4, 0.38, 0.45, 0.55)
const PATH_COLOR := Color(1.0, 0.8, 0.35)
const CHOICE_COLOR := Color(1.0, 0.92, 0.7, 0.95)
const INK := Color(0.07, 0.07, 0.1, 0.96)
const RADIUS := 26.0
const BOSS_RADIUS := 34.0

var _run: RunState
var _buttons: Dictionary = {}  # MapNode -> Button
var _centers: Dictionary = {}  # MapNode -> Vector2
var _hovered: RunMap.MapNode


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


func _process(_delta: float) -> void:
	if _run != null:
		queue_redraw()  # Choices pulse.


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _run != null:
		_layout()
		queue_redraw()


## Invisible click/hover area over the medallion and its caption.
func _make_button(node: RunMap.MapNode, is_choice: bool) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_choice else Control.CURSOR_ARROW
	var r := _radius(node)
	button.custom_minimum_size = Vector2(r * 2.0 + 40.0, r * 2.0 + 30.0)
	button.size = button.custom_minimum_size
	for state in [&"normal", &"hover", &"pressed", &"disabled", &"hover_pressed", &"focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.disabled = not is_choice
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_entered.connect(_on_hover.bind(node))
	button.mouse_exited.connect(_on_hover.bind(null))
	if is_choice:
		button.pressed.connect(func() -> void: node_chosen.emit(node))
	return button


func _on_hover(node: RunMap.MapNode) -> void:
	_hovered = node
	node_hovered.emit(node)


## Columns spread over the width, nodes centred vertically in each column.
func _layout() -> void:
	_centers.clear()
	var map := _run.get_map()
	var columns := map.get_layer_count()
	var margin := 60.0
	var step_x := (size.x - margin * 2.0) / maxf(columns - 1, 1)
	for layer in columns:
		var row: Array = map.get_layer(layer)
		var step_y := minf(120.0, (size.y - 120.0) / maxf(row.size() - 1, 1))
		var top := (size.y - step_y * (row.size() - 1)) / 2.0
		for node: RunMap.MapNode in row:
			var center := Vector2(margin + layer * step_x, top + node.index * step_y - 10.0)
			_centers[node] = center
			var button: Button = _buttons.get(node)
			if button != null:
				button.position = center - Vector2(button.size.x / 2.0, _radius(node) + 4.0)


func _radius(node: RunMap.MapNode) -> float:
	return BOSS_RADIUS if node.kind == RunMap.Kind.MINIBOSS else RADIUS


func _draw() -> void:
	if _run == null:
		return
	var map := _run.get_map()
	var choices := _run.get_choices()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	var font := get_theme_default_font()
	# Paths.
	for layer in map.get_layer_count() - 1:
		for node: RunMap.MapNode in map.get_layer(layer):
			for index in node.links:
				var next: RunMap.MapNode = map.get_layer(layer + 1)[index]
				var from: Vector2 = _centers.get(node, Vector2.ZERO)
				var to: Vector2 = _centers.get(next, Vector2.ZERO)
				if node.visited and next.visited:
					draw_line(from, to, PATH_COLOR, 5.0, true)
				elif node == _run.current_node and choices.has(next):
					draw_line(from, to, Color(CHOICE_COLOR, 0.5 + 0.5 * pulse), 3.5, true)
				else:
					_dashed(from, to, LINE_COLOR)
	if _run.current_node == null:
		for node in choices:
			var c: Vector2 = _centers[node]
			draw_line(c - Vector2(70, 0), c - Vector2(_radius(node) + 6, 0), Color(CHOICE_COLOR, 0.4 + 0.5 * pulse), 3.0, true)
	# Medallions.
	for node: RunMap.MapNode in _centers:
		var c: Vector2 = _centers[node]
		var r := _radius(node)
		var color: Color = KIND_COLORS[node.kind]
		var is_choice := choices.has(node)
		var dim := not is_choice and not node.visited
		if is_choice:
			draw_circle(c, r + 6.0 + pulse * 4.0, Color(color, 0.18 + 0.12 * pulse))
		if node == _hovered:
			draw_circle(c, r + 5.0, Color(1, 1, 1, 0.18))
		draw_circle(c, r, INK)
		draw_arc(c, r, 0.0, TAU, 48, color if not dim else color.darkened(0.55), 3.0, true)
		if node.visited:
			draw_arc(c, r + 4.0, 0.0, TAU, 48, PATH_COLOR, 2.0, true)
		_draw_icon(node.kind, c, r * 0.55, color if not dim else color.darkened(0.5))
		if node.objective != RunMap.Objective.NONE:
			draw_circle(c + Vector2(r * 0.75, -r * 0.75), 7.0, Color(0.4, 1.0, 0.6))
		var text: String = KIND_NAMES[node.kind]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
		draw_string(font, c + Vector2(-width / 2.0, r + 18.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			color if not dim else color.darkened(0.45))


## Simple vector icons (no font glyphs needed).
func _draw_icon(kind: RunMap.Kind, c: Vector2, s: float, color: Color) -> void:
	match kind:
		RunMap.Kind.COMBAT:
			draw_line(c + Vector2(-s, s), c + Vector2(s, -s), color, 3.0, true)
			draw_line(c + Vector2(s, s), c + Vector2(-s, -s), color, 3.0, true)
			draw_line(c + Vector2(-s * 0.85, s * 0.35), c + Vector2(-s * 0.35, s * 0.85), color, 3.0, true)
			draw_line(c + Vector2(s * 0.85, s * 0.35), c + Vector2(s * 0.35, s * 0.85), color, 3.0, true)
		RunMap.Kind.ELITE:
			draw_circle(c + Vector2(0, -s * 0.15), s * 0.75, color)
			draw_rect(Rect2(c + Vector2(-s * 0.45, s * 0.35), Vector2(s * 0.9, s * 0.45)), color)
			draw_circle(c + Vector2(-s * 0.3, -s * 0.15), s * 0.2, INK)
			draw_circle(c + Vector2(s * 0.3, -s * 0.15), s * 0.2, INK)
			for i in 3:
				draw_line(c + Vector2(-s * 0.3 + i * s * 0.3, s * 0.4), c + Vector2(-s * 0.3 + i * s * 0.3, s * 0.8), INK, 2.0)
		RunMap.Kind.RECRUIT:
			draw_circle(c + Vector2(0, -s * 0.45), s * 0.38, color)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.75, s * 0.85), c + Vector2(0, -s * 0.05),
				c + Vector2(s * 0.75, s * 0.85)]), color)
			draw_line(c + Vector2(s * 0.55, -s * 0.6), c + Vector2(s * 1.05, -s * 0.6), color, 3.0)
			draw_line(c + Vector2(s * 0.8, -s * 0.85), c + Vector2(s * 0.8, -s * 0.35), color, 3.0)
		RunMap.Kind.REST:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.5, s * 0.5), c + Vector2(0, -s * 0.9),
				c + Vector2(s * 0.5, s * 0.5)]), Color(1.0, 0.6, 0.25))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.25, s * 0.5), c + Vector2(0, -s * 0.3),
				c + Vector2(s * 0.25, s * 0.5)]), Color(1.0, 0.9, 0.5))
			draw_line(c + Vector2(-s, s * 0.75), c + Vector2(s, s * 0.55), color, 3.0)
			draw_line(c + Vector2(-s, s * 0.55), c + Vector2(s, s * 0.75), color, 3.0)
		RunMap.Kind.MINIBOSS:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.6), c + Vector2(-s, -s * 0.5),
				c + Vector2(-s * 0.5, s * 0.05), c + Vector2(0, -s * 0.8), c + Vector2(s * 0.5, s * 0.05),
				c + Vector2(s, -s * 0.5), c + Vector2(s, s * 0.6)]), color)
			draw_circle(c + Vector2(0, s * 0.2), s * 0.15, INK)


func _dashed(from: Vector2, to: Vector2, color: Color) -> void:
	var length := from.distance_to(to)
	var dir := (to - from) / maxf(length, 0.001)
	var t := 0.0
	while t < length:
		draw_line(from + dir * t, from + dir * minf(t + 8.0, length), color, 2.0, true)
		t += 14.0


## Spanish description of a node for the info panel.
static func describe(node: RunMap.MapNode) -> String:
	var text: String = KIND_HINTS[node.kind]
	if node.objective != RunMap.Objective.NONE:
		text += "\nObjetivo opcional: %s (premio: modificador + oro)." % OBJECTIVE_NAMES[node.objective].to_lower()
	return text
