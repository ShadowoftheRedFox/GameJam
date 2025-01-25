class_name MapRoom
extends Node2D

enum Backgrounds {
    NORMAL = 0
}

# WHY
# WHERE IS MY STD::OPTIONAL OR GO-LIKE ERROR HANDLING OR OPTION<T>
var room_id: int = -1
var room_position: Vector2 = Vector2(-1,-1)
# Oh yeah and unique IDs too ig
static var next_id: int = 0
# Connections to other nodes (up, down, left, right)
var up: MapRoom = null
var down: MapRoom = null
var left: MapRoom = null
var right: MapRoom = null
var room: Node2D = null
var room_type: String = ""

var PlayerSpawn: Marker2D = null
var BuffSpawn: Marker2D = null
var Map: TileMapLayer = null

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
    if body != GameController.main_player_instance:
        return
    # if door origin is not cleared yet
    if player_door_origin != "":
        return
    #print("player is going ", direction)
    # get the next room
    var next_room: MapRoom = get_connection(direction)
    if next_room == null:
        printerr("Can't find next room despite having connection")
        return
    # get the area from where the player will be coming from
    # and tell the next room where the player enter to prevent back and forth
    var door: Door = null
    if direction == "up":
        next_room.player_door_origin = "down"
        door = next_room.room.get_node("Map/Down")
    elif direction == "down":
        next_room.player_door_origin = "up"
        door = next_room.room.get_node("Map/Up")
    elif direction == "left":
        next_room.player_door_origin = "left"
        door = next_room.room.get_node("Map/Right")
    elif direction == "right":
        next_room.player_door_origin = "right"
        door = next_room.room.get_node("Map/Left")
    if door == null:
        printerr("Can't find area of next room despite having connection")
        return
    
    door.door_cleared = false
    # TODO transition
    # change player pos and display next room
    #get_tree().root.add_child.call_deferred(next_room)
    GameController.current_room = next_room
    GameController.main_player_instance.change_room(next_room.room_position)
    # FIXME get the same relative pos from door to door (and not spawn from center) or generalize doors
    GameController.main_player_instance.global_position = door.global_position
    #get_tree().root.remove_child.call_deferred(self)

# Called when the node is added to the scene tree for the first time
func _ready():
    check_room_valid()
    if room != null:
        add_child.call_deferred(room)

## Check if the room has all elements needed
func check_room_valid() -> void:
    if room == null:
        return
    
    # needs to have a Spawn and be a Marker2D
    assert(room.has_node("Spawn"), "Room " + room.scene_file_path + " has no Spawn Markder2D")
    assert(room.get_node("Spawn") is Marker2D,"Room " + room.scene_file_path + " Spawn is not a Markder2D")
    
    # needs to have a Map and be TileMapLayer
    assert(room.has_node("Map"), "Room " + room.scene_file_path + " has no Map TileMapLayer")
    assert(room.get_node("Map") is TileMapLayer, "Room " + room.scene_file_path + " Map is not a TileMapLayer")
    
    # needs to have a BuffSpawn and be Marker2D
    assert(room.has_node("BuffSpawn"), "Room " + room.scene_file_path + " has no BuffSpawn Markder2D")
    assert(room.get_node("BuffSpawn") is Marker2D, "Room " + room.scene_file_path + " BuffSpawn is not a Markder2D")
    
    # needs to have at least one door called either Up/Down/Left/Right and be a Door
    assert(room.has_node("Map/Up") or room.has_node("Map/Down") or room.has_node("Map/Left") or room.has_node("Map/Right"), "Room " + room.scene_file_path + " Map must at least have a Door")
    if room.has_node("Map/Up"):
        assert(room.get_node("Map/Up") is Door, "Room " + room.scene_file_path + " Map/Up is not a Door")
    if room.has_node("Map/Down"):
        assert(room.get_node("Map/Down") is Door, "Room " + room.scene_file_path + " Map/Down is not a Door")
    if room.has_node("Map/Left"):
        assert(room.get_node("Map/Left") is Door, "Room " + room.scene_file_path + " Map/Left is not a Door")
    if room.has_node("Map/Right"):
        assert(room.get_node("Map/Right") is Door, "Room " + room.scene_file_path + " Map/Right is not a Door")
        
    PlayerSpawn = room.get_node("Spawn")
    BuffSpawn = room.get_node("BuffSpawn")
    Map = room.get_node("Map")
    
    
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
            check_room_valid()
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
            check_room_valid()
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
    var door: Door = null
    if get_connection("down") != null and room.has_node("Map/Down"):
        door = room.get_node("Map/Down")
        door.collision_mask = AREA_COLLISION_MASK
        area_connect(door, "down")
    if get_connection("left") != null and room.has_node("Map/Left"):
        door = room.get_node("Map/Left")
        door.collision_mask = AREA_COLLISION_MASK
        area_connect(door, "left")
    if get_connection("right") != null and room.has_node("Map/Right"):
        door = room.get_node("Map/Right")
        door.collision_mask = AREA_COLLISION_MASK
        area_connect(door, "right")
    if get_connection("up") != null and room.has_node("Map/Up"):
        door = room.get_node("Map/Up")
        door.collision_mask = AREA_COLLISION_MASK
        area_connect(door, "up")
    
    
func area_connect(door: Door, direction: String) -> void:
    door.player_entered.connect(area_entered.bind(direction))
    door.player_exited.connect(area_leave)
    
func area_leave(_body: Node2D) -> void:
    player_door_origin = ""
