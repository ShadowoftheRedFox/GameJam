extends Node

var PlayerScene: PackedScene = load("res://scenes/entities/Player.tscn")
var node_scene: Node = null
# amount of player spawned
var index: int = 0

signal player_infos(ind:int)

func _ready() -> void:
    Server.player_disconnected.connect(handle_player_disconnection)
    
func handle_player_disconnection(id: int) -> void:
    # TODO maybe handle at the end of the frame to let other listeners the time to do their things
    remove_player.call_deferred(id)

@rpc("any_peer")
func send_player_infos(data: Dictionary) -> void:
    if Server.solo_active:
        # FIXME remove that when we spawn the multiplayer players at their correct position
        return
        
    if !Server.multiplayer_active:
        push_warning("Trying to send player info when no server active")
        return
    
    if !data.has("id"):
        printerr("Connected instances did not gives any id!")
        return
        
    player_infos.emit()
    
    if !GameController.game_started:
        printerr("Game has not started")
        return
    
    if node_scene == null:
        node_scene = get_tree().root.get_node("/root/" + GameController.MultiPlayerNodeName)
    
    if !GameController.Players.has(data.get("id", 0)):
        GameController.Players.get_or_add(data.get("id"), data)
        printerr("id in players: ", data.id)
        var player_data = GameController.Players.get(data.id, {})
        # player not in scene
        #if node_scene.get_node(str(data.id)) == null:
        spawn_player(player_data)
        
    # update all connected peers with the new data
    if multiplayer.is_server():
        printerr("From ", multiplayer.get_unique_id(),": Sending infos to peers")
        for i in GameController.Players:
            send_player_infos.rpc(GameController.Players.get(i, {}))
    
    # add a player if it isn't made yet
    # var index = 0
    
    # spawn ourself first
    #var player_data: Dictionary = {}
    #if GameController.Players.has(multiplayer.get_unique_id()):
    #    player_data = GameController.Players.get(multiplayer.get_unique_id(), {})
    #    spawn_player(player_data, index)
    #    index += 1
    #else:
    #    print(multiplayer.get_unique_id(), ": No infos on own id")
    #    return
    
    #for i in GameController.Players:
    #    printerr("id in players: ", i)
    #    var player_data = GameController.Players.get(i, {})
    #    # player not in scene
    #    if node_scene.get_node(str(i)) == null:
    #        spawn_player(player_data, index)
    #    index += 1

func spawn_player(player_data: Dictionary) -> void:
    var currentPlayer: BasePlayer = PlayerScene.instantiate()
    currentPlayer.name = str(player_data.id)
    currentPlayer.set_player_name(player_data.name)
    currentPlayer.set_authority(player_data.id)
    node_scene.add_child(currentPlayer)
    currentPlayer.disable_others_camera(player_data.id)
    printerr("From ", multiplayer.get_unique_id(),": New instance of Player ", player_data.id)
    # find a spawn for the player
    for spawn: Node2D in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
        if str(index) == spawn.name:
            currentPlayer.global_position = spawn.global_position
            index+=1
            break

func remove_player(id: int) -> void:
    var player_data = GameController.Players.get(id, {})
    node_scene.get_node(str(player_data.id)).queue_free()
    GameController.Players.erase(id)
