extends Node

# amount of player spawned
var index: int = 0

signal player_infos(data: Dictionary)
signal game_starting

func _ready() -> void:
    Server.player_disconnected.connect(handle_player_disconnection)
    Server.player_connected.connect(send_map_data)
    
func handle_player_disconnection(id: int) -> void:
    # handle at the end of the frame to let other listeners the time to do their things
    remove_player.call_deferred(id)

@rpc("any_peer")
func send_player_infos(data: Dictionary) -> void:        
    if !Server.multiplayer_active and !Server.solo_active:
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

@rpc("any_peer", "call_local")
func start_game() -> void:
    if Server.solo_active == false and Server.multiplayer_active == false:
        push_warning("Server is not active, can not use 'start_game'")
        return
    # tell our client listeners that the game is starting
    game_starting.emit()
    # TODO maybe host is spectator?
    GameController.hide_menu()
    GameController.game_started = true
    #var map: Node = GameController.MultiplayerScene.instantiate()
    #map.name = "MultiplayerScene"
    #get_tree().root.add_child(map)
    #GameController.current_room = map
    GameController.current_room = GameController.current_map[0][0]
    get_tree().root.add_child(GameController.current_room)
    # spawn all peer
    #if multiplayer.is_server():
    for i in GameController.Players:
        # TODO spawn player in different room and at coos
        spawn_player.call_deferred(GameController.Players.get(i, 1))

func spawn_player(player_data: Dictionary) -> void:
    var currentPlayer: BasePlayer = GameController.PlayerScene.instantiate()
    currentPlayer.name = str(player_data.id)
    currentPlayer.set_player_name(player_data.name)
    currentPlayer.set_authority(player_data.id)
    # FIXME change player spawn in multi
    get_tree().root.add_child(currentPlayer)
    currentPlayer.disable_others_camera(player_data.id)
    #Server.peer_print(Server.MessageType.ERR, "New instance of Player: " + str(player_data.id))
    # find a spawn for the player
    if GameController.current_room.room.has_node("Spawn"):
        var spawn = GameController.current_room.room.get_node("Spawn")
        currentPlayer.global_position = spawn.global_position
        currentPlayer.player_room = GameController.current_room.room_position
        index+=1
    # remember our own player
    if player_data.id == multiplayer.get_unique_id():
        GameController.main_player_instance = currentPlayer

@rpc("any_peer", "call_local")
func remove_player(id: int) -> void:
    if !GameController.game_started:
        GameController.Players.erase(id)
        return
    
    var player_data = GameController.Players.get(id, {})
    if get_tree().root.has_node(str(player_data.id)) == true:
        get_tree().root.get_node(str(player_data.id)).queue_free()
    GameController.Players.erase(id)
    index-=1

func send_map_data(id: int) -> void:
    if multiplayer.is_server():
        var save = SaveController.get_save(GameController.hosted_save_name)
        # FIXME do not pass whole save if something sensitive is added 
        receive_map_data.rpc_id(id, save[0])

@rpc("call_remote")
func receive_map_data(data: Dictionary) -> void:
    GameController.load_game.call_deferred("", data)

@rpc("any_peer", "call_local")
func player_change_room(id: int, room: Vector2) -> void:
    if !GameController.game_started:
        return
    if GameController.main_player_instance == null or !get_tree().root.has_node(str(id)):
        return
    
    var player: BasePlayer = get_tree().root.get_node(str(id))
        
    player.player_room = room
    
    if player.skip_next_player_room:
        player.skip_next_player_room = false
        return
    
    if id == multiplayer.get_unique_id():
        # update our player
        # to "force" the player to be in front of the layer on its same level
        player.move_to_front.call_deferred()
        # snap camera
        player.camera.snap()
        player.camera.set_limits(GameController.current_room.room.get_node("Map"))
        
        # if called from inside, change all other player nodes
        for children in get_tree().root.get_children():
            if children is BasePlayer:
                if children.player_room != player.player_room:
                    children.disable_player()
                else:
                    children.enable_player()
    else:
        # if called from outside, just change the player who changed room
        if GameController.main_player_instance.player_room == player.player_room:
            player.enable_player()
        else:
            player.disable_player()

@rpc("any_peer")
func player_buff_update(id: int, buff_data: Dictionary) -> void:
    # TODO tell which buff to remove globally
    if !GameController.game_started:
        return
    if !GameController.Players.has(id):
        push_warning("Updating buff on unknown player")
        return
    
    var player_data: Dictionary = GameController.Players.get(id, {})
    player_data.get_or_add("buff", {})
    player_data.buff = buff_data
    
    var player: BasePlayer = get_tree().root.get_node(str(id))
    player.update_buff(buff_data)
