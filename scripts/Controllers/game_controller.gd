extends Node

var save_name_hosted: String = ""
var Players = {}
const MultiplayerScene = preload("res://tests/multiplayer/roomtestmulti.tscn")
const MultiPlayerNodeName = "MultiplayerScene"
var game_started: bool = false
var current_map: Array = []
var current_room: MapRoom = null
# so, we need to keep track of player in solo between rooms
# so here we put the node
# TODO think of something similar for multiplayer
var player_node: BasePlayer = null

func new_game(save_name: String, difficulty: int, map_size: int) -> void:
    # TODO create save
    current_map = GeneratorController.generate_map(map_size)
    SaveController.create_new_save(save_name, JSON.stringify({
        "difficulty": difficulty,
        "map_size": map_size,
        "map": GeneratorController.get_map_room_types(current_map),
        "seed": GeneratorController.save_seed,
    }))
    launch_solo(save_name)

func load_game(save_name: String) -> void:
    print("loading map...")
    var save = SaveController.get_save(save_name)
    var save_data: Dictionary = save[0]
    current_map = GeneratorController.load_map(save_data.get("map"), save_data.get("map_size"), save_data.get("seed"))
    print("map loaded")

func launch_solo(save_name: String) -> void:
    var res: bool = Server.create_host(true)
    if res == false:
        push_warning("Server couldn't create host")
        return
    
    # TODO transition while loading
    save_name_hosted = save_name 
    load_game(save_name)
    hide_menu()
    game_started = true
    # display first room
    current_room = current_map[0][0]
    get_tree().root.add_child(current_room)
    # TODO spawn player at spawn location on solo
    player_node = load("res://scenes/entities/Player.tscn").instantiate()
    var anchor = current_room.room.get_node("Spawn")
    get_tree().root.add_child(player_node)
    player_node.global_position = anchor.global_position

func launch_multiplayer(save_name: String) -> void:
    var res: bool = Server.create_host()
    if res == false:
        push_warning("Server couldn't create host")
        return
    
    save_name_hosted = save_name
    
func join_multiplayer() -> bool:
    return Server.join_server()

@rpc("any_peer")
func start_game() -> void:
    hide_menu()
    game_started = true
    #var map: Node = MultiplayerScene.instantiate()
    #map.name = "MultiplayerScene"
    #get_tree().root.add_child(map)
    get_tree().root.add_child(current_map[0][0])
    # TODO load game and spread info to all peer
    # TODO spawn player in different room and at coos

func hide_menu() -> void:
    # hide main menu
    for child in get_tree().root.get_children():
        if child.name == "MainMenu":
            # queue free?
            child.set_visible(false)
