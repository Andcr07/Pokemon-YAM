@tool
extends "res://OpMon/Scenes/Events/Interactable/Character.gd"

const PlayerClass = preload("Player.gd")
const OpTeam = preload("res://OpMon/Objects/OpTeam.gd")
const OpMon = preload("res://OpMon/Objects/OpMon.gd")

var opponent_team: OpTeam

func _ready():
	super._ready()
	if not Engine.is_editor_hint():
		var tackle = load("res://OpMon/Data/GodotResources/Moves/Tackle.tres")
		var harden = load("res://OpMon/Data/GodotResources/Moves/Harden.tres")
		var ember = load("res://OpMon/Data/GodotResources/Moves/Ember.tres")
		var bot_nature = load("res://OpMon/Data/GodotResources/Natures/Bot.tres")
		var oopmon = OpMon.new("", load("res://OpMon/Data/GodotResources/Species/Carnapple.tres"), 10, 
		[tackle, harden, null, null], bot_nature)
		var oopmon2 = OpMon.new("", load("res://OpMon/Data/GodotResources/Species/Furnurus.tres"), 10, 
		[ember, harden, tackle, null], bot_nature)
		opponent_team = OpTeam.new([oopmon, oopmon2, null, null, null, null])

# Called when the player interacts with the NPC
func interact(player: PlayerClass):
	super.interact(player)
	if _moving != Vector2.ZERO:
		return
	_paused = true
	change_faced_direction(player.get_direction()) # Changes the faced direction of the NPC to face the player
	_map_manager.pause_player()
	var battle_scene = load("res://OpMon/Scenes/Battle/BattleScene.tscn").instantiate()
	battle_scene.init(_map_manager.player_data.team, opponent_team)
	_map_manager.load_interface(battle_scene)

func change_faced_direction(player_faced_direction):
	# Change the direction the NPC is facing based on the direction the player
	# is facing: if the player is facing up then face down, etc.
	if player_faced_direction == Vector2.UP:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.animation = "walk_down"
	elif player_faced_direction == Vector2.DOWN:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.animation = "walk_up"
	elif player_faced_direction == Vector2.RIGHT:
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.animation = "walk_side"
	elif player_faced_direction == Vector2.LEFT:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.animation = "walk_side"

func _unpause():
	_paused = false
