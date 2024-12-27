extends Node

enum GameModes {
    Classic = 0,
}
const GameModesNames = ["Classique"]

enum Difficulties {
    Easy = 0,
    Medium = 1,
    Hard = 2,
    Impossible = 3
}
const DifficultiesNames = ["Facile", "Normal", "Difficile", "Impossible"]

enum MapSizes {
    Small = 0,
    Medium = 1,
    Large = 2,
    Huge = 3
}
const MapSizesNames = ["Petite", "Grande", "Large", "Immense"]


var GeneratorController = GeneratorControllerScript.new()
var ThreadController = ThreadControllerScript.new()
var Utils = UtilsScript.new()

const MainMenuScene = preload("res://scenes/UI/Main/MainMenu.tscn")
const PlayerScene = preload("res://scenes/entities/Player.tscn")

signal game_loaded(result_map: Array)

var save_name_hosted: String = ""
var Players = {}
var game_started: bool = false
var game_paused: bool = false
var current_map: Array = []
var current_room: MapRoom = null
# we need to keep track of player in solo between rooms
# so here we put the node
# TODO think of something similar for multiplayer
var main_player_instance: BasePlayer = null

func _init() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    self.add_child(GeneratorController)
    self.add_child(ThreadController)
    self.add_child(Utils)

func new_game(save_name: String, difficulty: Difficulties, map_size: MapSizes, gamemode: GameModes) -> void:
    # create save
    current_map = GeneratorController.generate_map(map_size)
    if SaveController.create_new_save(save_name, JSON.stringify({
        "difficulty": difficulty,
        "gamemode": gamemode,
        "map_size": map_size,
        "map": GeneratorController.get_map_room_types(current_map),
        "seed": GeneratorController.save_seed,
    })):
        launch_solo(save_name)
    else:
        push_error("couldn't create new game")

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
    # TODO threading
    var thread := Thread.new()
    var err = thread.start(GeneratorController.load_map.bind(save_data.get("map"), save_data.get("map_size"), save_data.get("seed")))
    if err != OK:
        push_warning("Error while creating thread to load map: ", err)
        return
    TransitionController.start_transition("Chargement de la carte...", thread, GameController.game_loaded)

func launch_solo(save_name: String) -> void:
    var res: bool = Server.create_host(true)
    if res == false:
        push_warning("Server couldn't create host")
        return
    
    # TODO transition while loading
    save_name_hosted = save_name 
    # if current map is loaded, means new game, so don't need to load save
    if current_map.size() == 0:
        load_game(save_name)
        game_loaded.connect(launch_solo_after_load)
    else:
        launch_solo_after_load(current_map)

func launch_solo_after_load(load_result: Array):
    current_map = load_result
    hide_menu()
    game_started = true
    # display first room
    current_room = current_map[0][0]
    get_tree().root.add_child(current_room)
    # TODO spawn player at spawn location on solo
    main_player_instance = PlayerScene.instantiate()
    var anchor = current_room.room.get_node("Spawn")
    get_tree().root.add_child(main_player_instance)
    main_player_instance.global_position = anchor.global_position

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
            child.queue_free()

func show_menu() -> void:
    # show main menu
    get_tree().root.add_child(MainMenuScene.instantiate())

func pause() -> void:
    print("Called pause")
    GameController.game_paused = true
    main_player_instance.get_node("Camera2D/Pause").show()
    if Server.solo_active == true:
        get_tree().paused = true
    
func unpause() -> void: 
    print("Called unpause")
    GameController.game_paused = false
    main_player_instance.get_node("Camera2D/Pause").hide()
    if Server.solo_active == true:
        get_tree().paused = false

func stop_game(no_new_menu: bool = false) -> void:
    if game_started == true and multiplayer.is_server():
        SaveController.save_game(save_name_hosted)
    GeneratorController.free_map(current_map)
    if main_player_instance != null:
        main_player_instance.queue_free()
    if current_room != null:
        current_room.queue_free()
    
    for children in get_tree().root.get_children():
        if children is BasePlayer or children is MapRoom:
            children.queue_free()
    
    Server.stop_server()
    
    Utils.remove_signal_listener(game_loaded)
    GameController.Players = {}
    game_started = false
    current_map = []
    current_room = null
    main_player_instance = null
    if !no_new_menu:
        show_menu()
