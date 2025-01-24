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
const SpectatorScene = preload("res://scenes/UI/Spectator/Spectator.tscn")

signal game_loaded(result_map: Array)
@warning_ignore("unused_signal")
signal player_infos_update(data: PlayerData)
@warning_ignore("unused_signal")
signal spectator_update(id: int)
@warning_ignore("unused_signal")
signal game_starting
@warning_ignore("unused_signal")
signal lobby_ready(id: int) # everyone has finished loading the game

# current save data
var hosted_save_name: String = ""
var hosted_difficulty: Difficulties = Difficulties.Easy
var hosted_map_size: MapSizes = MapSizes.Small
var hosted_gamemode: GameModes = GameModes.Classic

# TODO find a way to differentiate players and spectator
var Players: PlayerDataManager = PlayerDataManager.new()
var game_started: bool = false
var game_paused: bool = false
var current_map: Array = []
var current_room: MapRoom = null
# we need to keep track of player in solo between rooms
# so here we put the node
# other player node are in root, and just need to be checked against their type
var main_player_instance: BasePlayer = null

func _init() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    self.add_child(GeneratorController)
    self.add_child(ThreadController)
    self.add_child(Utils)

func new_game(save_name: String, difficulty: Difficulties, map_size: MapSizes, gamemode: GameModes) -> void:
    # load game
    hosted_save_name = save_name
    hosted_difficulty = difficulty
    hosted_gamemode = gamemode
    hosted_map_size = map_size

    ThreadController.thread_transition(
        GeneratorController.generate_map.bind(map_size),
        game_loaded,
        true,
        "Création du monde en cours..."
    )
    game_loaded.connect(new_game_after_load)


func new_game_after_load(load_result: Array) -> void:
    current_map = load_result
    if SaveController.create_new_save(hosted_save_name, JSON.stringify({
        "difficulty": hosted_difficulty,
        "gamemode": hosted_gamemode,
        "map_size": hosted_map_size,
        "map": GeneratorController.get_map_room_types(current_map),
        "seed": GeneratorController.save_seed,
    })):
        launch_solo(hosted_save_name)
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

    # store data
    hosted_save_name = save_name
    hosted_difficulty = save_data.get("difficulty", 0)
    hosted_gamemode = save_data.get("gamemode", 0)
    hosted_map_size = save_data.get("map_size", 0)
    # tansition with thread
    ThreadController.thread_transition(
        GeneratorController.load_map.bind(save_data.get("map", []), hosted_map_size, save_data.get("seed", 0)),
        game_loaded,
        multiplayer_data.is_empty(), # don't show loading screen for players joining host
        "Chargement de la carte...",
    )

func launch_solo(save_name: String) -> void:
    var res: bool = Server.create_host(true)
    if res == false:
        push_warning("Server couldn't create host")
        return

    # if current map is loaded, means new game, so don't need to load save
    if current_map.size() == 0:
        load_game(save_name)
        game_loaded.connect(launch_solo_after_load)
    else:
        MultiplayerController.start_game()

func launch_solo_after_load(load_result: Array) -> void:
    current_map = load_result
    MultiplayerController.start_game()

func launch_multiplayer(save_name: String) -> void:
    var res: bool = Server.create_host()
    if res == false:
        push_warning("Server couldn't create host")
        return

    hosted_save_name = save_name
    load_game(save_name)
    game_loaded.connect(multiplayer_after_load)

func join_multiplayer() -> bool:
    game_loaded.connect(multiplayer_after_load)
    return Server.join_server()

func multiplayer_after_load(result: Array) -> void: 
    current_map = result
    lobby_readying.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer", "call_local")
func lobby_readying(id: int) -> void:
    lobby_ready.emit(id)

func hide_menu() -> void:
    # hide main menu
    for child in get_tree().root.get_children():
        if child is MainMenu:
            child.queue_free()

func show_menu() -> void:
    # make sure main menu is deleted
    hide_menu()
    # show main menu
    get_tree().root.add_child(MainMenuScene.instantiate())

func pause() -> void:
    main_player_instance.move_to_front()
    GameController.game_paused = true
    main_player_instance.pause.show()
    if Server.solo_active == true:
        get_tree().paused = true

func unpause() -> void:
    GameController.game_paused = false
    main_player_instance.pause.hide()
    if Server.solo_active == true:
        get_tree().paused = false

func stop_game(no_new_menu: bool = false) -> void:
    if game_started == true and multiplayer.is_server():
        SaveController.save_game(hosted_save_name)
    GeneratorController.free_map(current_map)
    if main_player_instance != null:
        main_player_instance.queue_free()
    if current_room != null:
        current_room.queue_free()

    for children in get_tree().root.get_children():
        if children is BasePlayer or children is MapRoom or children is SpectatorMenu:
            children.queue_free()

    Server.stop_server()

    Utils.remove_signal_listener(game_loaded)
    GameController.Players.reset()
    game_started = false
    current_map = []
    current_room = null
    main_player_instance = null

    hosted_save_name = ""
    hosted_difficulty = Difficulties.Easy
    hosted_map_size = MapSizes.Small
    hosted_gamemode = GameModes.Classic

    if !no_new_menu:
        show_menu()
