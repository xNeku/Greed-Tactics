extends TestCase
## Rage, mana and cooldowns (GDD §3 v0.3).

var combat: CombatState
var rules: RulesConfig


func before_each() -> void:
	rules = TestFixtures.rules()
	combat = CombatState.new(TestFixtures.flat_grid(6, 6), rules, 7)


## Advances turns until it is [param unit]'s. The previous turn must be ended.
func _start(unit: UnitState) -> void:
	for i in 50:
		var current := combat.start_next_turn()
		if current == unit:
			return
		combat.end_turn(current.facing)


func test_rage_grows_when_hitting_and_being_hit() -> void:
	var berserker := combat.add_unit(TestFixtures.rage_unit_data(), UnitState.Team.PLAYER, Vector2i(2, 2))
	var victim_data := TestFixtures.rage_unit_data("Victim")
	victim_data.speed = 1
	var victim := combat.add_unit(victim_data, UnitState.Team.ENEMY, Vector2i(2, 3))
	_start(berserker)
	combat.use_skill(berserker.data.skills[0], victim.cell)
	assert_eq(berserker.rage, rules.rage_on_hit_dealt)
	assert_true(victim.rage >= rules.rage_on_hit_taken, "being hit also builds rage")


func test_rage_increases_damage() -> void:
	var berserker := combat.add_unit(TestFixtures.rage_unit_data(), UnitState.Team.PLAYER, Vector2i(2, 2))
	var victim := combat.add_unit(TestFixtures.unit_data("Victim"), UnitState.Team.ENEMY, Vector2i(2, 3))
	var spender := berserker.data.skills[1]
	berserker.rage = 0
	var calm := combat.preview_skill(berserker, spender, berserker.cell, victim.cell)[0].damage
	berserker.rage = 40
	var angry := combat.preview_skill(berserker, spender, berserker.cell, victim.cell)[0].damage
	assert_true(angry > calm, "%d > %d" % [angry, calm])


func test_rage_cost_is_spent_and_required() -> void:
	var berserker := combat.add_unit(TestFixtures.rage_unit_data(), UnitState.Team.PLAYER, Vector2i(2, 2))
	combat.add_unit(TestFixtures.unit_data("Victim"), UnitState.Team.ENEMY, Vector2i(2, 3))
	_start(berserker)
	var spender := berserker.data.skills[1]
	assert_false(combat.can_use_skill(berserker, spender), "needs 30 rage")
	berserker.rage = 45
	assert_not_null(combat.use_skill(spender, Vector2i(2, 3)))
	assert_true(berserker.rage < 45, "rage spent (then some regained by hitting)")


func test_empowered_variant_is_used_above_threshold() -> void:
	var berserker := combat.add_unit(TestFixtures.rage_unit_data(), UnitState.Team.PLAYER, Vector2i(2, 2))
	var victim := combat.add_unit(TestFixtures.unit_data("Victim"), UnitState.Team.ENEMY, Vector2i(2, 3))
	var strike := berserker.data.skills[0]
	berserker.rage = 0
	var normal := combat.preview_skill(berserker, strike, berserker.cell, victim.cell)[0].damage
	berserker.rage = 50
	var empowered := combat.preview_skill(berserker, strike, berserker.cell, victim.cell)[0].damage
	assert_true(empowered > normal * 1.5, "mutated skill hits much harder")


func test_mana_is_spent_and_regenerates() -> void:
	var data := TestFixtures.unit_data("Mage", 20)
	data.resource_kind = UnitData.ResourceKind.MANA
	data.max_mp = 20
	data.skills[0].mp_cost = 8
	var mage := combat.add_unit(data, UnitState.Team.PLAYER, Vector2i(2, 2))
	combat.add_unit(TestFixtures.unit_data("Victim", 1), UnitState.Team.ENEMY, Vector2i(2, 3))
	_start(mage)
	combat.use_skill(data.skills[0], Vector2i(2, 3))
	assert_eq(mage.mp, 12)
	combat.end_turn(mage.facing)
	_start(mage)
	assert_eq(mage.mp, 12 + rules.mana_regen_per_turn)


func test_cooldown_blocks_reuse_for_n_turns() -> void:
	var data := TestFixtures.unit_data("Archer", 20)
	data.skills[0].cooldown = 2
	var archer := combat.add_unit(data, UnitState.Team.PLAYER, Vector2i(2, 2))
	var dummy := TestFixtures.unit_data("Dummy", 1)
	dummy.max_hp = 9999
	combat.add_unit(dummy, UnitState.Team.ENEMY, Vector2i(2, 3))
	var skill := data.skills[0]
	_start(archer)
	assert_not_null(combat.use_skill(skill, Vector2i(2, 3)))
	assert_false(combat.can_use_skill(archer, skill), "same turn")
	for turn in 2:
		combat.end_turn(archer.facing)
		_start(archer)
		assert_false(combat.can_use_skill(archer, skill), "turn %d after use" % (turn + 1))
	combat.end_turn(archer.facing)
	_start(archer)
	assert_true(combat.can_use_skill(archer, skill), "ready after 2 full turns")
