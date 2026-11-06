extends TestCase
## Weapons in the hand (v0.8): every hero carries its starting weapon, the
## hand pixels lie on its sprites and dual weapons mirror into the other hand.

const HEROES := "res://content/units/heroes"


func _heroes() -> Array[UnitData]:
	var result: Array[UnitData] = []
	for file in DirAccess.get_files_at(HEROES):
		if file.ends_with(".tres"):
			var data := load(HEROES.path_join(file)) as UnitData
			if data != null and not data.is_structure:
				result.append(data)
	return result


func _inside(cell: Vector2i, texture: Texture2D) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < texture.get_width() and cell.y < texture.get_height()


func test_every_playable_hero_has_a_weapon() -> void:
	for hero in _heroes():
		assert_not_null(hero.weapon, "%s has no weapon" % hero.id)


func test_drawn_weapons_have_hands_on_the_sprite_and_a_grip_on_the_weapon() -> void:
	for hero in _heroes():
		if hero.weapon == null or not hero.weapon.is_drawn():
			continue
		assert_true(_inside(hero.weapon.grip, hero.weapon.sprite), "%s grip" % hero.weapon.id)
		assert_true(_inside(hero.get_hand(false), hero.sprite), "%s front hand" % hero.id)
		if hero.sprite_side != null:
			assert_true(_inside(hero.get_hand(true), hero.sprite_side), "%s side hand" % hero.id)


func test_dual_weapon_mirrors_into_the_other_hand_in_front_view() -> void:
	var hero := UnitData.new()
	hero.hand_front = Vector2i(17, 20)
	assert_eq(hero.get_off_hand(false, 20), Vector2i(2, 20))
	hero.off_hand_front = Vector2i(4, 19)
	assert_eq(hero.get_off_hand(false, 20), Vector2i(4, 19), "a marked off hand wins")


func test_dual_weapon_peeks_out_behind_in_side_view() -> void:
	var hero := UnitData.new()
	hero.hand_side = Vector2i(10, 18)
	assert_eq(hero.get_off_hand(true, 16), Vector2i(10, 18) + UnitData.OFF_HAND_SIDE_OFFSET)
	var weapon := WeaponData.new()
	weapon.side_pose = WeaponPose.new()
	assert_true(weapon.get_off_pose(true).behind)
	assert_false(weapon.get_pose(true).behind, "the main pose is untouched")


func test_off_hand_pose_is_the_mirror_of_the_main_one() -> void:
	var weapon := WeaponData.new()
	weapon.front_pose = WeaponPose.new()
	weapon.front_pose.rotation_degrees = 70.0
	weapon.front_pose.scale = 0.75
	var off := weapon.get_off_pose(false)
	assert_eq(off.rotation_degrees, -70.0)
	assert_true(off.flip)
	assert_eq(off.scale, 0.75)


func test_no_hand_marked_means_no_off_hand() -> void:
	var hero := UnitData.new()
	assert_eq(hero.get_off_hand(false, 20), UnitData.NO_HAND)
	assert_eq(hero.get_off_hand(true, 16), UnitData.NO_HAND)


func test_starting_daggers_and_pistols_are_dual() -> void:
	for hero in _heroes():
		var weapon := hero.weapon
		if weapon != null and (weapon.kind == WeaponData.Kind.DAGGER or weapon.kind == WeaponData.Kind.PISTOL):
			assert_true(weapon.dual, "%s is dual" % weapon.id)
