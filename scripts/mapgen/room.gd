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
    
    # get our path in levels folder
    var path: String = ""
    if get_connection("down") != null:
        path += "down_"
    if get_connection("left") != null:
        path += "left_"
    if get_connection("right") != null:
        path += "right_"
    if get_connection("up") != null:
        path += "up_"
    if path.ends_with("_"):
        path = path.erase(len(path)-1)

    #print("Room ", room_id, " can choose between ", GeneratorController.get_num_files_in_dir("res://scenes/levels/" + path, ".tscn"), " scenes")
    var amount_room_available = GeneratorController.get_num_files_in_dir("res://scenes/levels/" + path, ".tscn")
    if amount_room_available == 0:
        printerr("No room available for ", path)
        return false
    
    var level_id = randi_range(0, amount_room_available -1)
    var room_path := "res://scenes/levels/" + path + "/" + str(level_id) + ".tscn" 
    if ResourceLoader.exists(room_path) :
        var resource: PackedScene = ResourceLoader.load(room_path, "PackedScene")
        if resource.can_instantiate():
            room = resource.instantiate()
        else:
            printerr("resource can't instantiate")
            return false
    else:
        printerr("can't find resource path")
        return false
        
    
    return true
