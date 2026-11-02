class_name AiAction
extends RefCounted
## One step decided by an AI: move, use a skill, or end the turn.

enum Kind { MOVE, SKILL, END_TURN }

var kind: Kind = Kind.END_TURN
var cell: Vector2i
var skill: SkillData
var facing: GridDir.Dir = GridDir.Dir.SOUTH


static func move(destination: Vector2i) -> AiAction:
	var action := AiAction.new()
	action.kind = Kind.MOVE
	action.cell = destination
	return action


static func use_skill(p_skill: SkillData, target_cell: Vector2i) -> AiAction:
	var action := AiAction.new()
	action.kind = Kind.SKILL
	action.skill = p_skill
	action.cell = target_cell
	return action


static func end_turn(p_facing: GridDir.Dir) -> AiAction:
	var action := AiAction.new()
	action.kind = Kind.END_TURN
	action.facing = p_facing
	return action
