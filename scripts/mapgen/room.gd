class_name MapRoom
extends Node

# WHY
# WHERE IS MY STD::OPTIONAL OR GO-LIKE ERROR HANDLING OR OPTION<T>
var room_id: int = -1
var room_position: Vector2 = Vector2(-1,-1)
# Oh yeah and unique IDs too ig
static var next_id: int = 0
# Connections to other nodes (up, down, left, right)
var up: Node = null
var down: Node = null
var left: Node = null
var right: Node = null
var room: Node = null
var room_type: String = ""

# to tell which layer trigger the event
const AREA_COLLISION_MASK: int = 0b1110

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
    # only care about our player 
    if body.name != GameController.main_player_instance.name:
        return
    # if door origin is not cleared yet
    if player_door_origin != "":
        return
    if GameController.main_player_instance == null:
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
    #get_tree().root.print_tree_pretty()
    get_tree().root.add_child.call_deferred(next_room)
    GameController.current_room = next_room
    GameController.main_player_instance.player_room = next_room.room_position
    # snap camera
    GameController.main_player_instance.camera.snap()
    GameController.main_player_instance.camera.set_limits(next_room.room.get_node("Map"))
    MultiplayerController.player_change_room.rpc(multiplayer.get_unique_id(), next_room.room_position)
    # FIXME get the same relative pos from door to door (and not spawn from center) or generalize doors
    GameController.main_player_instance.global_position = area.global_position
    get_tree().root.remove_child.call_deferred(self)
    # to "force" the player to be in front of the layer on its same level
    GameController.main_player_instance.move_to_front()
    

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
    if get_connection("left") != null:
        path += "left_"
    if get_connection("right") != null:
        path += "right_"
    if get_connection("up") != null:
        path += "up_"
        
    if path.ends_with("_"):
        path = path.erase(len(path)-1)

    #print("Room ", room_id, " can choose between ", GameController.Utils.get_num_files_in_dir("res://scenes/levels/" + path, ".tscn"), " scenes")
    var amount_room_available = GameController.Utils.get_num_files_in_dir("res://scenes/levels/" + path, ".tscn")
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
        
    # setup area listeners
    set_area_listeners.call_deferred()
    
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
            "up":
                set_connection("up", room_up)               
            "left":
                set_connection("left", room_left)
            "right":
                set_connection("right", room_right)
    
    # setup area listeners
    set_area_listeners.call_deferred()
    
    return true

func set_area_listeners() -> void:
    var area: Area2D = null
    if get_connection("down") != null and room.has_node("Map/Down"):
        area = room.get_node("Map/Down")
        area.collision_mask = AREA_COLLISION_MASK
        area_connect(area, "down")
    if get_connection("left") != null and room.has_node("Map/Left"):
        area = room.get_node("Map/Left")
        area.collision_mask = AREA_COLLISION_MASK
        area_connect(area, "left")
    if get_connection("right") != null and room.has_node("Map/Right"):
        area = room.get_node("Map/Right")
        area.collision_mask = AREA_COLLISION_MASK
        area_connect(area, "right")
    if get_connection("up") != null and room.has_node("Map/Up"):
        area = room.get_node("Map/Up")
        area.collision_mask = AREA_COLLISION_MASK
        area_connect(area, "up")
    
    
func area_connect(area: Area2D, direction: String) -> void:
    area.body_entered.connect(area_entered.bind(direction))
    area.body_exited.connect(area_leave)
    
func area_leave(_body: Node2D) -> void:
    player_door_origin = ""
