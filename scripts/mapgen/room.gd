class_name MapRoom
extends Node

# WHY
# WHERE IS MY STD::OPTIONAL OR GO-LIKE ERROR HANDLING OR OPTION<T>
var room_id: int = -1
# Oh yeah and unique IDs too ig
static var next_id: int = 0
# Connections to other nodes (up, down, left, right)
var up: Node = null
var down: Node = null
var left: Node = null
var right: Node = null
# TODO: ADD THE PROPER ROOM HERE
var room: Node = null

# Self-explainatory
func set_connection(direction: String, node: Node):
	match direction:
		"up":
			up = node
		"down":
			down = node
		"left":
			left = node
		"right":
			right = node

# It really shouldn't be that hard.
func get_connection(direction: String) -> Node:
	match direction:
		"up":
			return up
		"down":
			return down
		"left":
			return left
		"right":
			return right
		# WHY
		# WHERE IS MY STD::EXPECTED, OR GO-LIKE ERROR HANDLING OR RESULT<T, E>
		_:
			return null

# Called when the node is added to the scene tree for the first time
func _ready():
	$Label.text = str(room_id)

func show_id():
	$Label.show()
	$Map.hide()

func hide_id():
	$Label.hide()
	$Map.show()
	
func generate_room() -> bool:
	if room_id == -1:
		printerr("Room has not been generated yet")
		return false
	if left == null and right == null and up == null and down == null:
		printerr("Room is not connected to any otehr room!")
		return false
	
	return true
