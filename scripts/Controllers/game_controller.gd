extends Node

var save_name_hosted: String = ""
var Players = {}
const MultiplayerScene = preload("res://tests/multiplayer/roomtestmulti.tscn")
const MultiPlayerNodeName = "MultiplayerScene"

func new_game(save_name: String, difficulty: int, map_size: int) -> void:
    # TODO create save
    GeneratorController.generate_map(map_size)
    SaveController.create_new_save(save_name, JSON.stringify({
        "difficulty": difficulty,
        "map_size": map_size,
        "seed": GeneratorController.seed,
    }))


func load_game(save_name: String) -> void:
    pass

func launch_solo(save_name: String) -> void:
    var res: bool = Server.create_host(true)
    if res == false:
        push_warning("Server couldn't create host")
        return
    
    save_name_hosted = save_name
    start_game()

func launch_multiplayer(save_name: String) -> void:
    var res: bool = Server.create_host()
    if res == false:
        push_warning("Server couldn't create host")
        return
    
    save_name_hosted = save_name
    start_game()
    
    
func join_multiplayer() -> void:
    Server.join_server()


func start_game() -> void:
    # TODO load map
    # hide main menu
    for child in get_tree().root.get_children():
        if child.name == "MainMenu":
            child.set_visible(false)
        
    var map: Node = MultiplayerScene.instantiate()
    map.name = "MultiplayerScene"
    get_tree().root.add_child(map)
