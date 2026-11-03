extends TestCase
## Summons (totems), structures and auras.

var combat: CombatState
var shaman: UnitState
var totem_data: UnitData
var throw_totem: SkillData


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(10, 10), TestFixtures.rules(), 4)
	totem_data = TestFixtures.totem_data()
	throw_totem = TestFixtures.summon_skill(totem_data)
	var data := TestFixtures.unit_data("Shaman", 30)
	data.skills.append(throw_totem)
	shaman = combat.add_unit(data, UnitState.Team.PLAYER, Vector2i(1, 1))
	combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, Vector2i(8, 8))


func _turn_of(unit: UnitState) -> void:
	for i in 60:
		var current := combat.start_next_turn()
		if current == unit:
			return
		combat.end_turn(current.facing)


func test_summon_places_a_structure_of_the_user_team() -> void:
	_turn_of(shaman)
	var result := combat.use_skill(throw_totem, Vector2i(3, 1))
	assert_not_null(result.summoned)
	assert_eq(result.summoned.team, UnitState.Team.PLAYER)
	assert_eq(combat.get_unit_at(Vector2i(3, 1)), result.summoned)
	assert_true(result.summoned.is_structure())


func test_summon_needs_an_empty_cell() -> void:
	combat.add_unit(TestFixtures.unit_data("Ally"), UnitState.Team.PLAYER, Vector2i(3, 1))
	_turn_of(shaman)
	assert_not_has(combat.get_targetable_cells(shaman, throw_totem, shaman.cell), Vector2i(3, 1))


func test_new_totem_replaces_the_old_one() -> void:
	_turn_of(shaman)
	var first := combat.use_skill(throw_totem, Vector2i(3, 1)).summoned
	var second := combat.use_skill(throw_totem, Vector2i(1, 3))
	assert_false(first.is_alive())
	assert_eq(second.replaced, first)


func test_structures_never_get_turns() -> void:
	_turn_of(shaman)
	var totem := combat.use_skill(throw_totem, Vector2i(3, 1)).summoned
	combat.end_turn(shaman.facing)
	for i in 10:
		var unit := combat.start_next_turn()
		assert_ne(unit, totem)
		combat.end_turn(unit.facing)
	assert_not_has(combat.get_turn_preview(8), totem)


func test_structures_do_not_count_for_victory() -> void:
	_turn_of(shaman)
	combat.use_skill(throw_totem, Vector2i(3, 1))
	shaman.hp = 0
	combat.end_turn(shaman.facing)
	var foe := combat.get_living_units(UnitState.Team.ENEMY)[0]
	foe.cell = Vector2i(2, 1)
	_turn_of(foe)
	foe.data.skills[0].power = 999
	combat.use_skill(foe.data.skills[0], Vector2i(3, 1))
	assert_true(combat.is_finished(), "only the totem was left")
	assert_eq(combat.winner, UnitState.Team.ENEMY)


func test_aura_buffs_allies_and_hinders_enemies_in_range() -> void:
	var ally := combat.add_unit(TestFixtures.unit_data("Ally", 25), UnitState.Team.PLAYER, Vector2i(4, 2))
	var foe_near := combat.add_unit(TestFixtures.unit_data("Near", 24), UnitState.Team.ENEMY, Vector2i(5, 1))
	_turn_of(shaman)
	combat.use_skill(throw_totem, Vector2i(4, 1))
	combat.end_turn(shaman.facing)
	_turn_of(ally)
	assert_true(ally.has_status(totem_data.aura.ally_status), "ally within 2 gets the buff")
	assert_eq(ally.get_damage_bonus_percent(), 50)
	combat.end_turn(ally.facing)
	_turn_of(foe_near)
	assert_true(foe_near.has_status(totem_data.aura.enemy_status), "enemy within 2 gets the debuff")
	assert_false(shaman.has_status(totem_data.aura.ally_status), "the shaman at distance 3 does not")


func test_damage_bonus_status_increases_damage() -> void:
	var foe := combat.get_living_units(UnitState.Team.ENEMY)[0]
	foe.cell = Vector2i(2, 1)
	var basic := shaman.data.skills[0]
	var before := combat.preview_skill(shaman, basic, shaman.cell, foe.cell)[0].damage
	shaman.add_status(totem_data.aura.ally_status, 1)
	var after := combat.preview_skill(shaman, basic, shaman.cell, foe.cell)[0].damage
	assert_eq(after, roundi(before * 1.5))
