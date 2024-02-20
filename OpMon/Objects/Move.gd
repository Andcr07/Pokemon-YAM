extends Resource

# Class Move: Represent the raw data of a move. For an actual move object that
# evolves in the game (pp and other modificators), see the OpMove class in the OpMon object

class_name Move

const Type = preload("res://OpMon/Objects/Enumerations.gd").Type

enum Category {PHYSICAL, SPECIAL, STATUS}

@export_group("Properties")
@export var id: String # used for storage in the code and the transations
@export_range(0, 200) var power: int
@export var type: Type
@export_range(0, 100) var accuracy: int
@export var category: Category
@export var never_fails: bool
@export_range(5, 60) var max_power_points: int
# 15 for top priority, 1 for low priority, uniquely determines the priority for prioritary moves
# if 0, the move is not prioritary, the order of action will be determined by speed
@export_range(0, 15) var priority: int # (int, 0, 15)

@export_group("Effects")
# Must contain resources of the type MoveEffect (Godot does not support exporting custom resources yet)
# Leave empty for no effects
# Effects will be called in the order first to last
@export var pre_effect: Array[MoveEffect]
@export var post_effect: Array[MoveEffect]
@export var fail_effect: Array[MoveEffect]

@export_group("Animations")
@export var move_animation: String

func _init(p_id = "", p_power = 0, p_type = Type.NONE, p_accuracy = 0, p_category = Category.PHYSICAL,
p_never_fails = false, p_max_power_points = 50, p_priority = 0, p_pre_effect: Array[MoveEffect] = [], p_post_effect: Array[MoveEffect] = [],
p_fail_effect: Array[MoveEffect] = [], p_move_animation = "NONE"):
	id = p_id
	power = p_power
	type = p_type
	accuracy = p_accuracy
	category = p_category
	never_fails = p_never_fails
	max_power_points = p_max_power_points
	priority = p_priority
	pre_effect = p_pre_effect
	post_effect = p_post_effect
	fail_effect = p_fail_effect
	move_animation = p_move_animation
