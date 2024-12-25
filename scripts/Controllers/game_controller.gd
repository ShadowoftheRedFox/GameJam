extends Node

var save_name_hosted: String = ""
var Players = {}
const MultiplayerScene = preload("res://tests/multiplayer/roomtestmulti.tscn")
const MultiPlayerNodeName = "MultiplayerScene"
const PlayerScene = preload("res://scenes/entities/Player.tscn")
var game_started: bool = false
var game_paused: bool = false
var current_map: Array = []
var current_room: MapRoom = null
# we need to keep track of player in solo between rooms
# so here we put the node
# TODO think of something similar for multiplayer
var player_node: BasePlayer = null

func _init() -> void:
    process_mode = PROCESS_MODE_ALWAYS

func new_game(save_name: String, difficulty: int, map_size: int) -> void:
    # create save
    current_map = GeneratorController.generate_map(map_size)
    SaveController.create_new_save(save_name, JSON.stringify({
        "difficulty": difficulty,
        "map_size": map_size,
        "map": GeneratorController.get_map_room_types(current_map),
        "seed": GeneratorController.save_seed,
    }))
    launch_solo(save_name)

func load_game(save_name: String, multiplayer_data: Dictionary = {}) -> void:
    print("loading map...")
    var save: Array[Dictionary] = []
    var save_data: Dictionary  = {}
    # load from ultiplayer data
    if !multiplayer_data.is_empty() and save_name == "":
        save_data = multiplayer_data
    else:
        save = SaveController.get_save(save_name)
        save_data = save[0]
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
    player_node = PlayerScene.instantiate()
    var anchor = current_room.room.get_node("Spawn")
    get_tree().root.add_child(player_node)
    player_node.global_position = anchor.global_position

func launch_multiplayer(save_name: String) -> void:
    var res: bool = Server.create_host()
    if res == false:
        push_warning("Server couldn't create host")
        return
    
    save_name_hosted = save_name
    load_game(save_name)
    
func join_multiplayer() -> bool:
    return Server.join_server()

func hide_menu() -> void:
    # hide main menu
    for child in get_tree().root.get_children():
        if child.name == "MainMenu":
            # queue free?
            child.set_visible(false)

func show_menu() -> void:
    # show main menu
    for child in get_tree().root.get_children():
        if child.name == "MainMenu":
            # queue free?
            child.set_visible(true)

func pause() -> void:
    print("Called pause")
    GameController.game_paused = true
    player_node.get_node("Camera2D/Pause").show()
    if Server.solo_active == true:
        get_tree().paused = true
    
func unpause() -> void: 
    print("Called unpause")
    GameController.game_paused = false
    player_node.get_node("Camera2D/Pause").hide()
    if Server.solo_active == true:
        get_tree().paused = false

func stop_game() -> void:
    if game_started == true:
        SaveController.save_game(save_name_hosted)
    GeneratorController.free_map(current_map)
    if player_node != null:
        player_node.queue_free()
    if current_room != null:
        current_room.queue_free()
    Server.stop_server()
    GameController.Players = {}
    
    game_started = false
    current_map = []
    current_room = null
    player_node = null
    show_menu()
