class_name FlickerLight
extends OmniLight3D
## Light of a fire or a failing lamp: its energy dances around the base
## energy times the mood factor (BattleLighting scales prop lights).

@export var base_energy := 1.6
## 0 = steady, 1 = wild.
@export_range(0.0, 1.0) var flicker := 0.25
@export var speed := 9.0
## Failing lamp: drops out now and then.
@export var stutter := false

var _factor := 1.0
var _time := randf() * 100.0


func _ready() -> void:
	add_to_group(BattleLighting.PROP_LIGHTS_GROUP)


func set_mood_factor(factor: float) -> void:
	_factor = factor
	visible = factor > 0.01


func _process(delta: float) -> void:
	_time += delta * speed
	var wave := sin(_time) * 0.5 + sin(_time * 2.7 + 1.3) * 0.3 + sin(_time * 5.1) * 0.2
	var energy := base_energy * (1.0 + wave * flicker)
	if stutter and fmod(_time, 23.0) < 0.6:
		energy *= 0.1
	light_energy = energy * _factor
