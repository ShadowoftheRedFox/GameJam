extends Node2D

# This is a mess.
const Map_generator = preload("res://scenes/mapgen/generator.tscn")
var gen = Map_generator.instantiate()
const WIDTH: int = 10
const HEIGHT: int = 10
const EXTRA_CONNECTION_PROBABILITY = 0.1
var map = gen.create_map(WIDTH, HEIGHT, EXTRA_CONNECTION_PROBABILITY)


# Prints the node ID list to the console.
func _ready() -> void:
	for row in map:
		for room in row:
			room.show_id()
			print(" ", room.room_id, " ")
		print("\n")

# Visually draw out the nodes
func _draw():
	var node_size = 50
	var margin = 10

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var node = map[y][x]
			# Move the node away from the generator and into this scene
			# node.get_parent().remove_child(node)
			add_child(node)
			node.position = Vector2(x * (node_size + margin) + margin, y * (node_size + margin) + margin)

	for row in map:
		for node in row:
			var start_pos = node.position
			if node.get_connection("up") != null:
				draw_line(start_pos, node.get_connection("up").position, Color(1, 1, 1), 2)
			if node.get_connection("down") != null:
				draw_line(start_pos, node.get_connection("down").position, Color(1, 1, 1), 2)
			if node.get_connection("left") != null:
				draw_line(start_pos, node.get_connection("left").position, Color(1, 1, 1), 2)
			if node.get_connection("right") != null:
				draw_line(start_pos, node.get_connection("right").position, Color(1, 1, 1), 2)
