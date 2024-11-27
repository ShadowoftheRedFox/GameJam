extends Node


const Map_generator = preload("res://scenes/mapgen/generator.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var gen = Map_generator.instantiate()
    var map = gen.create_map(10, 10)
    for row in map:
        for room in row:
            print(" ", room.room_id, " ")
        print("\n")
    var map2 = gen.create_map(10, 10)
    for row in map2:
        for room in row:
            print(" ", room.room_id, " ")
        print("\n")
