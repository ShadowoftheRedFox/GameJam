class_name NewGame
extends Node

@export var MAP_WIDTH: int = 10
@export var MAP_HEIGHT: int = 10
@export var EXTRA_CONNECTION_PROBABILITY: float = 0.1

@export var ROOM_WIDTH: int = 10
@export var ROOM_HEIGHT: int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_pressed() -> void:
	new_game()

func new_game() -> void:
	print("Starting new game...")
	print("Generating map...")
	var generator = MapGenerator.new()
	var map: Array = generator.create_map(MAP_WIDTH, MAP_HEIGHT, EXTRA_CONNECTION_PROBABILITY)
	if len(map) == 0:
		printerr("Something went wrong when generating map, found size 0")
		return
	print("Generating rooms...")
	for row: Array in map:
		for room: MapRoom in row:
			var res: bool = room.generate_room()
			if not res:
				printerr("Something went wrong with room ", room.room_id)
				return
	# TODO save map and show it
	# TODO where to spawn player
	print("Rooms generated, starting...")
	
	
