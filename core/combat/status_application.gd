class_name StatusApplication
extends RefCounted
## "Apply [member status] with [member chance]% for [member duration] turns",
## coming from a skill or a modifier.

var status: StatusData
## 0-100
var chance: int = 100
var duration: int = 0


static func create(p_status: StatusData, p_chance: int, p_duration: int) -> StatusApplication:
	var app := StatusApplication.new()
	app.status = p_status
	app.chance = clampi(p_chance, 0, 100)
	app.duration = p_duration if p_duration > 0 else p_status.default_duration
	return app


## Keeps one entry per status, with the best chance and duration.
static func merge(into: Array[StatusApplication], app: StatusApplication) -> void:
	for existing in into:
		if existing.status == app.status:
			existing.chance = maxi(existing.chance, app.chance)
			existing.duration = maxi(existing.duration, app.duration)
			return
	into.append(app)
