extends Node

# amount of player spawned
var index: int = 0

signal player_infos(data: Dictionary)

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
        
    if !GameController.Players.has(data.id):
        GameController.Players.get_or_add(data.id, data)
        player_infos.emit(data)
    
    # update all connected peers with the new data
    if multiplayer.is_server():
        Server.peer_print(Server.MessageType.PRINT, "Sending infos to peers")
        for i in GameController.Players:
            send_player_infos.rpc(GameController.Players.get(i, {}))
    else:
        Server.peer_print(Server.MessageType.PRINT, "Getting infos from host")
    
    #if !GameController.game_started:
        #printerr("Game has not started")
        #return
    #
    #if node_scene == null:
        #node_scene = get_tree().root.get_node("/root/" + GameController.MultiPlayerNodeName)
    #
    #if !GameController.Players.has(data.get("id", 0)):
        #GameController.Players.get_or_add(data.get("id"), data)
        ##printerr("id in players: ", data.id)
        #var player_data = GameController.Players.get(data.id, {})
        ## player not in scene
        ##if node_scene.get_node(str(data.id)) == null:
        #spawn_player(player_data)
    
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

@rpc("any_peer", "call_local")
func start_game() -> void:
    if Server.solo_active == true or Server.multiplayer_active == false:
        push_warning("Server is not multiplayer, can not use 'start_game'")
        return
    # TODO maybe host is spectator?
    GameController.hide_menu()
    GameController.game_started = true
    var map: Node = GameController.MultiplayerScene.instantiate()
    map.name = "MultiplayerScene"
    get_tree().root.add_child(map)
    GameController.current_room = map
    #get_tree().root.add_child(GameController.current_map[0][0])
    #GameController.current_room = GameController.current_map[0][0]
    # TODO load game and spread info to all peer
    # TODO spawn player in different room and at coos
    if multiplayer.is_server():
        for i in GameController.Players:
            spawn_player.rpc(GameController.Players.get(i, 1))

@rpc("any_peer", "call_local")
func spawn_player(player_data: Dictionary) -> void:
    var currentPlayer: BasePlayer = GameController.PlayerScene.instantiate()
    currentPlayer.name = str(player_data.id)
    currentPlayer.set_player_name(player_data.name)
    currentPlayer.set_authority(player_data.id)
    # FIXME change player spawn in multi
    GameController.current_room.add_child(currentPlayer)
    currentPlayer.disable_others_camera(player_data.id)
    #Server.peer_print(Server.MessageType.ERR, "New instance of Player: " + str(player_data.id))
    # find a spawn for the player
    for spawn: Node2D in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
        if str(index) == spawn.name:
            currentPlayer.global_position = spawn.global_position
            index+=1
            break

@rpc("any_peer", "call_local")
func remove_player(id: int) -> void:
    if !GameController.game_started:
        GameController.Players.erase(id)
        return
    
    var player_data = GameController.Players.get(id, {})
    if GameController.current_room.has_node(str(player_data.id)) == true:
        GameController.current_room.get_node(str(player_data.id)).queue_free()
    GameController.Players.erase(id)
    index-=1
