class_name FeedbackArrows
extends Node3D
## Pool of ArcArrows and BlockMarkers that shows, before confirming, what an
## action will do: green = movement, red = attack, orange = push, yellow =
## bounce chain, grey = the part of a move you cannot reach this turn.
## Arrows are reused by index so they glide when the hovered cell changes.

enum Kind { MOVE, MOTION, ATTACK, PUSH, CHAIN, OUT_OF_REACH }

const COLORS := {
	Kind.MOVE: Color(0.35, 1.0, 0.5, 0.95),
	Kind.MOTION: Color(0.45, 1.0, 0.75, 1.0),
	Kind.ATTACK: Color(1.0, 0.28, 0.25, 1.0),
	Kind.PUSH: Color(1.0, 0.62, 0.2, 1.0),
	Kind.CHAIN: Color(1.0, 0.85, 0.3, 0.9),
	Kind.OUT_OF_REACH: Color(0.7, 0.72, 0.8, 0.45),
}

@export var arrow_scene: PackedScene
@export var marker_scene: PackedScene

var _arrows: Array[ArcArrow] = []
var _markers: Array[BlockMarker] = []
var _pending: Array[Dictionary] = []
var _pending_markers: Array[Vector3] = []


## Queues an arrow for the next [method commit].
func add(from: Vector3, to: Vector3, kind: Kind) -> void:
	_pending.append({"from": from, "to": to, "kind": kind})


## Queues a "blocked here" cross.
func add_marker(world_position: Vector3) -> void:
	_pending_markers.append(world_position)


## Shows everything queued since the last commit and hides the rest.
func commit() -> void:
	while _arrows.size() < _pending.size():
		var arrow: ArcArrow = arrow_scene.instantiate()
		add_child(arrow)
		_arrows.append(arrow)
	for i in _arrows.size():
		if i < _pending.size():
			_arrows[i].point(_pending[i].from, _pending[i].to, COLORS[_pending[i].kind])
		else:
			_arrows[i].hide_arrow()
	while _markers.size() < _pending_markers.size():
		var marker: BlockMarker = marker_scene.instantiate()
		add_child(marker)
		_markers.append(marker)
	for i in _markers.size():
		_markers[i].visible = i < _pending_markers.size()
		if _markers[i].visible:
			_markers[i].global_position = _pending_markers[i]
	_pending.clear()
	_pending_markers.clear()


func clear() -> void:
	_pending.clear()
	_pending_markers.clear()
	commit()
