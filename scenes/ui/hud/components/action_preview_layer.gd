class_name ActionPreviewLayer
extends Control
## Keeps one PreviewCard above each previewed target, following the camera.

@export var card_scene: PackedScene
## Screen offset from the projected anchor (card is centered horizontally).
@export var screen_offset := Vector2(0.0, -24.0)
## Gap between cards that would overlap.
@export var card_spacing := 6.0
## Cards never go above this screen height (top bar + message banner).
@export var min_top := 120.0

var _camera: Camera3D
var _cards: Array[PreviewCard] = []
var _anchors: Array[Vector3] = []


func set_camera(camera: Camera3D) -> void:
	_camera = camera


## [param anchors] are world positions (one per preview) to place the cards at.
func show_previews(previews: Array[AttackPreview], anchors: Array[Vector3]) -> void:
	clear()
	for i in previews.size():
		var card: PreviewCard = card_scene.instantiate()
		add_child(card)
		card.show_preview(previews[i])
		_cards.append(card)
		_anchors.append(anchors[i])
	_update_positions()


func clear() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	_anchors.clear()


func _process(_delta: float) -> void:
	_update_positions()


func _update_positions() -> void:
	if _camera == null:
		return
	# Place each card above its target, then push overlapping cards sideways
	# (left to right) and keep them inside the screen, under the top bar.
	var order: Array[int] = []
	var rects: Dictionary[int, Rect2] = {}
	for i in _cards.size():
		var card := _cards[i]
		card.visible = not _camera.is_position_behind(_anchors[i])
		var screen := _camera.unproject_position(_anchors[i])
		rects[i] = Rect2(screen + screen_offset - Vector2(card.size.x * 0.5, card.size.y), card.size)
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return rects[a].position.x < rects[b].position.x)
	var viewport := get_viewport_rect().size
	var placed: Array[Rect2] = []
	for i in order:
		var rect := rects[i]
		for other in placed:
			if rect.grow(-2.0).intersects(other):
				rect.position.x = other.end.x + card_spacing
		rect.position.x = clampf(rect.position.x, card_spacing, viewport.x - rect.size.x - card_spacing)
		rect.position.y = clampf(rect.position.y, min_top, viewport.y - rect.size.y - card_spacing)
		placed.append(rect)
		_cards[i].position = rect.position
