class_name ModifierOffer
extends RefCounted
## Picks the modifiers offered at a checkpoint (GDD §5: choose 1 of 3).
## Only offers modifiers that affect at least one skill of the party and that
## are compatible with everything already owned. Behaviour modifiers already
## owned are not offered again (they would not stack).


static func roll(pool: Array[ModifierData], owned: Array[ModifierData], party_tags: Array[StringName],
		count: int, rng: RandomNumberGenerator) -> Array[ModifierData]:
	var candidates: Array[ModifierData] = []
	for modifier in pool:
		if modifier.target_tag != &"" and not party_tags.has(modifier.target_tag):
			continue
		if modifier.is_behavior() and owned.has(modifier):
			continue
		if not owned.all(func(o: ModifierData) -> bool: return o.is_compatible_with(modifier)):
			continue
		candidates.append(modifier)

	var result: Array[ModifierData] = []
	while result.size() < count and not candidates.is_empty():
		var total := 0
		for modifier in candidates:
			total += modifier.weight
		var pick := rng.randi_range(1, total)
		for i in candidates.size():
			pick -= candidates[i].weight
			if pick <= 0:
				result.append(candidates.pop_at(i))
				break
	return result
