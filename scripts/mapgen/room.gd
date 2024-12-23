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
var room: Node = null
var room_type: String = ""

# to know from where the player come from to prevent back and forth
var player_door_origin: String = ""

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

func area_entered(body: Node2D, direction: String) -> void:
    # if door origin is not cleared yet
    if player_door_origin != "":
        return
    if body.name != GameController.player_node.name:
        return
    #print("player is going ", direction)
    # get the next room
    var next_room: MapRoom = get_connection(direction)
    if next_room == null:
        printerr("Can't find next room despite having connection")
        return
    # get the area from where the player will be coming from
    # and tell the next room where the player enter to prevent back and forth
    var area: Area2D = null
    if direction == "up":
        next_room.player_door_origin = "down"
        area = next_room.room.get_node("Map/Down")
    if direction == "down":
        next_room.player_door_origin = "up"
        area = next_room.room.get_node("Map/Up")
    if direction == "left":
        next_room.player_door_origin = "left"
        area = next_room.room.get_node("Map/Right")
    if direction == "right":
        next_room.player_door_origin = "right"
        area = next_room.room.get_node("Map/Left")
    if area == null:
        printerr("Can't find area of next room despite having connection")
        return
    # TODO transition
    # change player pos and display next room
    get_tree().root.add_child(next_room)
    GameController.current_room = next_room
    # FIXME get the same relative pos from door to door (and not spawn from center)
    GameController.player_node.global_position = area.global_position
    get_tree().root.remove_child.call_deferred(self)
    

# Called when the node is added to the scene tree for the first time
func _ready():
    if room != null:
        self.add_child.call_deferred(room)

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
        var area: Area2D = $Map/Up
        if area != null:
            area.body_entered.connect(area_entered.bind("down"), CONNECT_PERSIST)
    if get_connection("left") != null:
        path += "left_"
        var area: Area2D = $Map/Down
        if area != null:
            area.body_entered.connect(area_entered.bind("left"), CONNECT_PERSIST)
    if get_connection("right") != null:
        path += "right_"
        var area: Area2D = $Map/Left
        if area != null:
            area.body_entered.connect(area_entered.bind("right"), CONNECT_PERSIST)
    if get_connection("up") != null:
        path += "up_"
        var area: Area2D = $Map/Right
        if area != null:
            area.body_entered.connect(area_entered.bind("up"), CONNECT_PERSIST)
        
    if path.ends_with("_"):
        path = path.erase(len(path)-1)

    #print("Room ", room_id, " can choose between ", GeneratorController.get_num_files_in_dir("res://scenes/levels/" + path, ".tscn"), " scenes")
    var amount_room_available = GeneratorController.get_num_files_in_dir("res://scenes/levels/" + path, ".tscn")
    if amount_room_available == 0:
        printerr("No room available for ", path)
        return false
    
    var level_id = randi_range(0, amount_room_available -1)
    var room_path := "res://scenes/levels/" + path + "/" + str(level_id) + ".tscn" 
    room_type = path + "/" + str(level_id)
    if ResourceLoader.exists(room_path):
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

func set_room(type: String, room_left: Node, room_right: Node, room_up: Node, room_down: Node) -> bool:
    var room_path := "res://scenes/levels/" + type + ".tscn" 
    room_type = type
    if ResourceLoader.exists(room_path):
        var resource: PackedScene = ResourceLoader.load(room_path, "PackedScene")
        if resource.can_instantiate():
            room = resource.instantiate()
        else:
            printerr("resource can't instantiate")
            return false
    else:
        printerr("can't find resource path")
        return false

    var directions = room_type.split("/")[0]
    # bind area to the next room
    for direction in directions.split("_"):
        match direction:
            "down":
                set_connection("down", room_down)
                var area_down: Area2D = room.get_node("Map/Down")
                if area_down != null:
                    area_down.ready.connect(area_connect.bind(area_down, "down"))
            "up":
                set_connection("up", room_up)               
                var area_up: Area2D = room.get_node("Map/Up")
                if area_up != null:
                    area_up.ready.connect(area_connect.bind(area_up, "up"))
            "left":
                set_connection("left", room_left)
                var area_left: Area2D = room.get_node("Map/Left")
                if area_left != null:
                    area_left.ready.connect(area_connect.bind(area_left, "left"))
            "right":
                set_connection("right", room_right)
                var area_right: Area2D = room.get_node("Map/Right")
                if area_right != null:
                    area_right.ready.connect(area_connect.bind(area_right, "right"))
    
    return true

func area_connect(area: Area2D, direction: String) -> void:
    area.body_entered.connect(area_entered.bind(direction), CONNECT_DEFERRED)
    area.body_exited.connect(area_leave, CONNECT_DEFERRED)
    
func area_leave(_body: Node2D) -> void:
    #print("cleared door")
    player_door_origin = ""
