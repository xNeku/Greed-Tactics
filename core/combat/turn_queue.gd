class_name TurnQueue
extends RefCounted
## Speed-based charge-time (CT) turn order (GDD §3).
##
## Every tick each living unit gains CT equal to its speed. The first unit to
## reach the threshold acts, then pays the threshold back. Ties are broken by
## higher CT, then by lower unit id, so the order is fully deterministic.

var _threshold: int


func _init(threshold: int) -> void:
	_threshold = threshold


## Advances time until someone can act and returns that unit (CT not yet paid).
func advance(units: Array[UnitState]) -> UnitState:
	var living := _living(units)
	if living.is_empty():
		return null
	var ticks := _ticks_until_next(living, _ct_of(living))
	for unit in living:
		unit.ct += unit.data.speed * ticks
	return _pick_ready(living, _ct_of(living))


## Called when [param unit] finishes its turn.
func pay_turn(unit: UnitState) -> void:
	unit.ct = maxi(unit.ct - _threshold, 0)


## Simulates the next [param count] turns without touching real state.
## If [param current] is given it is listed first and treated as having paid.
func preview(units: Array[UnitState], count: int, current: UnitState = null) -> Array[UnitState]:
	var result: Array[UnitState] = []
	var living := _living(units)
	if living.is_empty():
		return result
	var ct := _ct_of(living)
	if current != null and current.is_alive():
		result.append(current)
		ct[current] = maxi(ct[current] - _threshold, 0)
	while result.size() < count:
		var ticks := _ticks_until_next(living, ct)
		for unit in living:
			ct[unit] += unit.data.speed * ticks
		var next := _pick_ready(living, ct)
		result.append(next)
		ct[next] = maxi(ct[next] - _threshold, 0)
	return result


func _ticks_until_next(living: Array[UnitState], ct: Dictionary[UnitState, int]) -> int:
	var best := 1 << 30
	for unit in living:
		var missing := _threshold - ct[unit]
		var ticks := 0 if missing <= 0 else ceili(float(missing) / unit.data.speed)
		best = mini(best, ticks)
	return best


func _pick_ready(living: Array[UnitState], ct: Dictionary[UnitState, int]) -> UnitState:
	var best: UnitState = null
	for unit in living:
		if ct[unit] < _threshold:
			continue
		if best == null or ct[unit] > ct[best] or (ct[unit] == ct[best] and unit.id < best.id):
			best = unit
	return best


func _living(units: Array[UnitState]) -> Array[UnitState]:
	return units.filter(func(u: UnitState) -> bool: return u.is_alive())


func _ct_of(units: Array[UnitState]) -> Dictionary[UnitState, int]:
	var ct: Dictionary[UnitState, int] = {}
	for unit in units:
		ct[unit] = unit.ct
	return ct
