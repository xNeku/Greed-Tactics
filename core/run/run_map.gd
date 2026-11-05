class_name RunMap
extends RefCounted
## Branching map of one stage (GDD §2, v0.7): layers of nodes from left to
## right, each node linked to 1-2 nodes of the next layer. The last layer is
## the miniboss. The player picks a path; every choice is a risk/reward call.

enum Kind { COMBAT, ELITE, RECRUIT, REST, MINIBOSS }
enum Objective { NONE, PROTECT, ESCAPE }

class MapNode:
	var kind: Kind = Kind.COMBAT
	var layer: int = 0
	var index: int = 0
	## Indices of the linked nodes in the next layer.
	var links: Array[int] = []
	## Optional battle objective (COMBAT only): meeting it gives a bonus.
	var objective: Objective = Objective.NONE
	var visited := false

	func is_battle() -> bool:
		return kind == Kind.COMBAT or kind == Kind.ELITE or kind == Kind.MINIBOSS

var layers: Array = []  # Array[Array[MapNode]]


## [param layer_count] includes the miniboss layer. [param recruits_wanted]
## RECRUIT nodes are guaranteed on different layers (when there is room).
static func generate(layer_count: int, config: RunConfig, rng: RandomNumberGenerator, recruits_wanted: int) -> RunMap:
	var map := RunMap.new()
	var recruit_layers: Array[int] = []
	var candidates: Array[int] = []
	for layer in range(1, layer_count - 1):
		candidates.append(layer)
	for i in range(candidates.size() - 1, 0, -1):  # Seeded shuffle: same seed, same map.
		var j := rng.randi_range(0, i)
		var swap := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	for i in mini(recruits_wanted, candidates.size()):
		recruit_layers.append(candidates[i])
	for layer in layer_count:
		var row: Array[MapNode] = []
		var width := 1 if layer == layer_count - 1 else rng.randi_range(config.map_min_width, config.map_max_width)
		for index in width:
			var node := MapNode.new()
			node.layer = layer
			node.index = index
			node.kind = map._roll_kind(layer, layer_count, rng, config)
			row.append(node)
		if recruit_layers.has(layer) and not row.any(func(n: MapNode) -> bool: return n.kind == Kind.RECRUIT):
			row[rng.randi_range(0, row.size() - 1)].kind = Kind.RECRUIT
		for node in row:
			if node.kind == Kind.COMBAT and rng.randf() < config.objective_chance:
				node.objective = Objective.PROTECT if rng.randf() < 0.5 else Objective.ESCAPE
		map.layers.append(row)
	map._link(rng)
	return map


func get_layer(layer: int) -> Array:
	return layers[layer]


func get_layer_count() -> int:
	return layers.size()


## Nodes the player can pick next: the first layer at the start, then the
## links of the last visited node.
func get_choices(current: MapNode) -> Array[MapNode]:
	var result: Array[MapNode] = []
	if current == null:
		for node: MapNode in layers[0]:
			result.append(node)
		return result
	if current.layer + 1 >= layers.size():
		return result
	for index in current.links:
		result.append(layers[current.layer + 1][index])
	return result


func _roll_kind(layer: int, layer_count: int, rng: RandomNumberGenerator, config: RunConfig) -> Kind:
	if layer == layer_count - 1:
		return Kind.MINIBOSS
	if layer == 0:
		return Kind.COMBAT
	var roll := rng.randf()
	if roll < config.elite_chance:
		return Kind.ELITE
	if roll < config.elite_chance + config.rest_chance and layer >= layer_count - 2:
		return Kind.REST
	return Kind.COMBAT


## Each node links to the closest nodes of the next layer (1-2 links) and every
## node of the next layer gets at least one incoming link.
func _link(rng: RandomNumberGenerator) -> void:
	for layer in layers.size() - 1:
		var row: Array = layers[layer]
		var next: Array = layers[layer + 1]
		var reached: Dictionary[int, bool] = {}
		for node: MapNode in row:
			var ratio := 0.0 if row.size() == 1 else float(node.index) / (row.size() - 1)
			var target := roundi(ratio * (next.size() - 1))
			node.links = [target]
			reached[target] = true
			var extra := target + (1 if rng.randf() < 0.5 else -1)
			if extra >= 0 and extra < next.size() and rng.randf() < 0.6:
				node.links.append(extra)
				reached[extra] = true
		for index in next.size():
			if not reached.has(index):
				var closest: MapNode = row[roundi(float(index) / maxi(next.size() - 1, 1) * (row.size() - 1))]
				closest.links.append(index)
		for node: MapNode in row:
			node.links.sort()
