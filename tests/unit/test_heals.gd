extends TestCase
## Skills with heal_percent: allies (user included) inside the area recover HP,
## enemies take damage, and the forecast matches the result.

var combat: CombatState
var paladin: UnitState
var ally: UnitState
var far_ally: UnitState
var foe: UnitState
var nova: SkillData


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(9, 9), TestFixtures.rules(), 3)
	var data := TestFixtures.unit_data("Paladin", 20)
	nova = TestFixtures.skill(10)
	nova.target_rule = SkillData.TargetRule.SELF
	nova.area_shape = AreaShape.Shape.DIAMOND
	nova.area_size = 2
	nova.heal_percent = 20
	data.skills = [nova]
	paladin = combat.add_unit(data, UnitState.Team.PLAYER, Vector2i(4, 4))
	ally = combat.add_unit(TestFixtures.unit_data("Ally", 1), UnitState.Team.PLAYER, Vector2i(4, 6))
	far_ally = combat.add_unit(TestFixtures.unit_data("Far", 1), UnitState.Team.PLAYER, Vector2i(8, 8))
	foe = combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, Vector2i(5, 4))
	combat.start_next_turn()


func test_heals_allies_in_area_including_the_user() -> void:
	paladin.hp = 50
	ally.hp = 30
	far_ally.hp = 30
	var result := combat.use_skill(nova, paladin.cell)
	assert_eq(paladin.hp, 70)
	assert_eq(ally.hp, 50)
	assert_eq(far_ally.hp, 30, "out of the area")
	assert_eq(result.heals[ally], 20)
	assert_true(foe.hp < foe.max_hp, "enemies still take damage")
	assert_false(result.heals.has(foe))


func test_heal_never_exceeds_max_hp_and_forecast_matches() -> void:
	ally.hp = ally.max_hp - 5
	var forecast := combat.preview_heals(paladin, nova, paladin.cell, paladin.cell)
	assert_eq(forecast[ally], 5)
	assert_eq(forecast[paladin], 0, "full HP: nothing to heal")
	var result := combat.use_skill(nova, paladin.cell)
	assert_eq(ally.hp, ally.max_hp)
	assert_eq(result.heals[ally], forecast[ally])
