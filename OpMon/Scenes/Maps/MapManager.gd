# Manages the current map, the camera and the switching from a scene to another one.
# It also manages the player in the overworld.
extends Node

class_name MapManager

const _constants = preload("res://OpMon/Utils/Constants.gd")

var _first_map := ""
var _first_player_pos := Vector2(0,0)

var current_map := ""

var maps := {}

var next_map := ""

# The instance of Player used in the overworld. Contains the camera.
var player_instance: Node

var player_data: PlayerData

var camera_instance: Camera2D

# Interface stack. The upper interfaces need to be unloaded before the bottom ones can be.
# Be careful when programming to not close interfaces in the wrong order
var interface: Array[Node]

# Loaded data from a save
var load_data = null

# Sets a cooldown after closing the interface
# During the cooldown, the player is still paused and the menu can’t open
# Unpauses the player at the end of the cooldown
# -1 if the cooldown is over
var interface_closed_delay := -1

# p_first_map path to the first map from the Maps directory
# p_first_player_pos in tiles
func init(p_first_map: String, p_first_player_pos := Vector2.ZERO):
	_first_map = p_first_map
	_first_player_pos = p_first_player_pos

func _ready():
	player_instance = load(_constants.PATH_PLAYER_SCENE).instantiate()
	camera_instance = load(_constants.PATH_CAMERA_SCENE).instantiate()
	player_data = get_node("/root/PlayerData")
	camera_instance.set_map_mode()
	player_instance.add_child(camera_instance)
	change_map(_first_map, _first_player_pos)
	if load_data != null:
		maps[current_map].load_events(load_data["current_map"]["data"])
		player_data.load_save(load_data)
		player_instance.load_save(load_data["player_character"])
	
func _input(event):
	if event.is_action_pressed("menu") and interface_closed_delay < 0 and not player_instance.is_moving() and interface.is_empty():
		var menu = load("res://OpMon/Scenes/GameMenu/GameMenu.tscn").instantiate()
		pause_player()
		load_interface(menu)
	
func _process(_delta):
	if interface_closed_delay > 0:
		interface_closed_delay -= 1
	if interface_closed_delay == 0:
		interface_closed_delay -= 1
		if interface.size() == 0:
			unpause_player()

# Loads an interface at the top of the stack
func load_interface(p_interface: Node):
	if p_interface.has_method("set_map"):
		interface.append(p_interface)
		p_interface.set_map(self)
		$Interface.add_child(interface[interface.size() - 1])
	else:
		print("Error: the given interface doesn’t have the set_map method.")

# Unloads the interface at the top of the stack
func unload_interface():
	var id := interface.size() - 1
	if interface[id] != null:
		interface[id].call_deferred("free")
		interface.remove_at(id)
		interface_closed_delay = 5

# Loads a map at the given position in the global MapManager and erases all the current present maps
# Does not associate the map with the player yet, only shows the map on screen
# map_pos and player_pos has to be in map coordinates (one tile = 16 px) and relatively to the loaded map
func change_map(map_name: String, player_pos = Vector2(0,0), map_pos = Vector2(0,0)):
	print("[MAPNAGER] Loading map " + map_name)
	if maps.has(current_map):
		maps[current_map].call_deferred("remove_child", player_instance)
	# Removes the old maps
	for key in maps.keys():
		maps[key].call_deferred("queue_free")
		maps.erase(key)
	# Loads the new map
	current_map = map_name
	maps[map_name] = load(_constants.PATH_MAP_SCENE + map_name + ".tscn").instantiate()
	maps[current_map].connect("map_entered", Callable(self, "map_entered"))
	# Sets the positions
	maps[current_map].position = map_pos * _constants.TILE_SIZE
	player_instance.position = player_pos * _constants.TILE_SIZE
	# Adds the map to the tree and loads adjacent maps
	call_deferred("add_child", maps[current_map])
	maps[current_map].call_deferred("add_child", player_instance)
	maps[current_map].show_adjacent_maps(self, maps)
	maps[current_map].emit_signal("map_loaded")


# Called when the player enters a map already shown on the screen but hasn’t finished walking through a square.
# It connects square_tick to switch_map so the map can be switched as soon as the character finished walking.
func map_entered(map):
	if next_map == "":
		next_map = get_map_key(map)
		player_instance.connect("square_tick", Callable(self, "switch_map"))

# Called when the player enters a map already shown on the screen and has finished walking on a square.
# Switches the main map to the new one
func switch_map():
	if next_map != current_map and next_map != "":
		print("[MAPNAGER] Switching map")
		# Moving the player
		var old_player_instance = player_instance
		player_instance = player_instance.duplicate()
		maps[next_map].call_deferred("add_child", player_instance)
		maps[current_map].call_deferred("remove_child", old_player_instance)
		player_instance.position += maps[current_map].position
		player_instance.position -= maps[next_map].position
		
		# Changing maps status
		maps[current_map].adjacent_mode(self, maps[next_map])
		maps[next_map].main_mode(self, maps, maps[current_map])
		current_map = next_map
		player_data.current_map = current_map
	next_map = ""
	player_instance.disconnect("square_tick", Callable(self, "switch_map"))


func get_map_key(map) -> String:
	for key in maps.keys():
		if maps[key] == map:
			return key
	return ""
	
func fade(duration: float):
	var fade: Fade = load(_constants.PATH_FADE_SCENE).instantiate()
	var tween = fade.tween
	fade.set_size(get_viewport().size)
	fade.duration = duration
	$Interface.add_child(fade)
	return fade
	
func unfade(duration: float, fade: Fade):
	fade.unfade(duration)
	
	fade.tween.tween_callback(Callable(self, "remove_fade"))
	
func remove_fade(object, _key):
	object.call_deferred("queue_free")
	unpause_player()

func pause_player():
	player_instance.set_paused(true)

func unpause_player():
	player_instance.set_paused(false)

# Only loads the dialog and returns it.
func load_dialog(dialog_key: String) -> DialogBox:
	var dialog_box_instance = load(_constants.PATH_DIALOG_BOX_SCENE).instantiate() # Loads the dialog
	dialog_box_instance.set_dialog_key(dialog_key) # Adds the dialog lines to the dialog
	dialog_box_instance.close_when_over = true
	load_interface(dialog_box_instance)
	return dialog_box_instance

func save() -> void:
	var to_save := player_data.save()
	to_save["current_map"]["data"] = maps[current_map].save_events()
	to_save["current_map"]["name"] = current_map
	to_save["player_character"] = player_instance.save()
	# Since the player is always paused in the menu to save
	# and we want the player to be able to move after loading
	to_save["player_character"]["_paused"] = false
	var save_file := FileAccess.open("user://opsave.json", FileAccess.WRITE)
	save_file.store_line(JSON.new().stringify(to_save))
	save_file.close()
	
func load_save() -> bool:
	if FileAccess.file_exists("user://opsave.json"):
		var save_file := FileAccess.open("user://opsave.json", FileAccess.READ)
		var test_json_conv = JSON.new()
		test_json_conv.parse(save_file.get_as_text())
		load_data = test_json_conv.get_data()
		self.init(load_data["current_map"]["name"])
		# Next step in _ready()
		return true
	else:
		printerr("No save file found.")
		return false
