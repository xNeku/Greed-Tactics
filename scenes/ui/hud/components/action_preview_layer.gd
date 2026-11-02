class_name ActionPreviewLayer
extends Control
## Keeps one PreviewCard above each previewed target, following the camera.

@export var card_scene: PackedScene
## Screen offset from the projected anchor (card is centered horizontally).
@export var screen_offset := Vector2(0.0, -24.0)

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
	for i in _cards.size():
		var card := _cards[i]
		card.visible = not _camera.is_position_behind(_anchors[i])
		var screen := _camera.unproject_position(_anchors[i])
		card.position = screen + screen_offset - Vector2(card.size.x * 0.5, card.size.y)
