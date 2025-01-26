extends Node

# amount of player spawned
var index: int = 0

func _ready() -> void:
    Server.player_disconnected.connect(handle_player_disconnection)
    Server.player_connected.connect(send_map_data)

func handle_player_disconnection(id: int) -> void:
    # handle at the end of the frame to let other listeners the time to do their things
    remove_player.call_deferred(id)

@rpc("any_peer")
func send_player_infos(data_raw: String) -> void:
    var data := PlayerData.new(data_raw)
    if data == null:
        push_error("received null as player data")
        return
    if !Server.multiplayer_active and !Server.solo_active:
        push_warning("Trying to send player info when no server active")
        return
        
    if !GameController.Players.has_player(data.id):
        GameController.Players.list.append(data)
        GameController.player_infos_update.emit(data)
    
    # update all connected peers with the new data
    if multiplayer.is_server():
        Server.peer_print(Server.MessageType.PRINT, "Sending infos to peers")
        for i in GameController.Players.get_players_ids():
            send_player_infos.rpc(str(GameController.Players.get_player(i)))
    else:
        Server.peer_print(Server.MessageType.PRINT, "Getting infos from host")

@rpc("authority", "call_local")
func start_game() -> void:
    if Server.solo_active == false and Server.multiplayer_active == false:
        push_warning("Server is not active, can not use 'start_game'")
        return
        
    # add all the scene with their data
    for y in GameController.current_map.size():
        for x in GameController.current_map[y].size():
            var room: MapRoom = GameController.current_map[y][x]
            GameController.MapNodes.add_child(room)
            
            var tile_map = room.Map
            var tile_rect = tile_map.get_used_rect()
            var cell_size = tile_map.tile_set.tile_size
            var limit_left = tile_rect.position.x * cell_size.x
            var limit_top = tile_rect.position.y * cell_size.y
            
            room.position.x = x * GameController.room_size.x + abs(limit_left)
            room.position.y = y * GameController.room_size.y + abs(limit_top)

    # tell our client listeners that the game is starting
    GameController.game_starting.emit()
    GameController.hide_menu()
    GameController.game_started = true
    GameController.current_room = GameController.current_map[0][0]
    
    # sort in ID order to make sure everyone spawn correctly
    GameController.Players.list.sort_custom(func sort_spawn(a: PlayerData, b: PlayerData): return a.id < b.id)
    # spawn all peer instances
    for p in GameController.Players.list:
        # TODO spawn player in different room and at coos
        if !p.is_spectator:
            spawn_player.call_deferred(p)

    # spawn if own is spectator
    if GameController.Players.get_player(multiplayer.get_unique_id()).is_spectator:
        GameController.MenuNodes.add_child(GameController.SpectatorScene.instantiate())

func spawn_player(player_data: PlayerData) -> void:
    if player_data == null:
        push_error("player data is null")
        return
    
    # find a spawn for the player
    var spawn = _work_position()
    var spawn_room: MapRoom = GameController.current_map[spawn.y][spawn.x]
    GameController.current_room = spawn_room
    
    var currentPlayer: BasePlayer = GameController.PlayerScene.instantiate()
    currentPlayer.player_spawn = spawn
    currentPlayer.global_position = spawn_room.PlayerSpawn.global_position
    #currentPlayer.name = str(player_data.id)
    currentPlayer.set_player_name(player_data.name)
    currentPlayer.set_authority(player_data.id)
    
    GameController.Players.add_node(player_data.id, currentPlayer)
    currentPlayer.change_room(spawn)
    currentPlayer.disable_others_camera(player_data.id)
    currentPlayer.camera.snap()
    currentPlayer.camera.set_limits(spawn_room.Map)
        
    index += 1
    #Server.peer_print(Server.MessageType.ERR, "New instance of Player: " + str(player_data.id))
    
    # remember our own player
    if player_data.id == multiplayer.get_unique_id():
        GameController.main_player_instance = currentPlayer

@rpc("any_peer", "call_local")
func remove_player(id: int) -> void:
    if !GameController.Players.has_player(id):
        return

    if !GameController.game_started:
        GameController.Players.erase_player(id)
        return
    
    #var player_data = GameController.Players.get_player(id)
    if GameController.Players.has_node(id):
        GameController.Players.get_node(id).queue_free()
    GameController.Players.erase_player(id)
    index -= 1
    # no player_infos_update because we should be listening to player disconnect instead

func send_map_data(id: int) -> void:
    if multiplayer.is_server():
        var save = SaveController.get_save(GameController.hosted_save_name)
        # FIXME do not pass whole save if something sensitive is added 
        receive_map_data.rpc_id(id, save[0])

@rpc("call_remote")
func receive_map_data(data: Dictionary) -> void:
    GameController.load_game.call_deferred("", data)

@rpc("any_peer", "reliable")
func player_buff_update(id: int, data_raw: String) -> void:
    var data := PlayerData.new(data_raw)
    # TODO tell which buff to remove globally
    if !GameController.game_started:
        return
    if !GameController.Players.has_player(id):
        push_warning("Updating buff on unknown player")
        return
    
    var player_data := GameController.Players.get_player(id)
    player_data.buff = data.buff
    
    var player: BasePlayer = GameController.Players.get_node(id)
    player.update_buff(player_data)
    GameController.player_infos_update.emit(player_data)

@rpc("any_peer", "call_local")
func update_spectator(id: int, is_spectator: bool) -> void:
    if GameController.Players.has_player(id):
        GameController.Players.get_player(id).is_spectator = is_spectator
        GameController.spectator_update.emit(id)

func _work_position() -> Vector2:
    var size_y = GameController.current_map.size()
    var size_x = GameController.current_map[0].size()
    
    # random
#region Random
    var selected = Vector2(randi_range(0, size_x), randi_range(0, size_y))
    for p: BasePlayer in GameController.PlayerNodes.get_children():
        if p.player_spawn == selected:
            return _work_position()            
#endregion
    return Vector2(randi_range(0, size_x - 1), randi_range(0, size_y - 1))
    
    # repartition
#region Repartition
    @warning_ignore("unreachable_code")
    var rx = 0
    var ry = 0

    match index % 4:
        0:
            rx = 0 + int(index / 4.0)
            ry = 0 + int(index / 4.0)
        1:
            rx = size_x - 1 + int(index / 4.0) * size_x
            ry = size_y - 1 + int(index / 4.0) * size_y
        2: 
            rx = (size_y) * (size_x - 1) - int(index / 4.0) * size_x
            ry = (size_y) * (size_x - 1) - int(index / 4.0) * size_y
        3:
            rx = size_y * size_x - 1 - int(index / 4.0)
            ry = size_y * size_x - 1 - int(index / 4.0)
#endregion
    return Vector2(rx % size_x, int(ry / size_y))
    
    # matrix
#region Matrix
    var base_x = randi_range(0, size_x - 1)
    var base_y = randi_range(0, size_y - 1)
    var angle = deg_to_rad(360.0 / float(GameController.Players.get_player_count()))

    var x = int(base_x * cos(angle * index) - base_y * sin(angle * index))
    var y = int(base_x * sin(angle * index) + base_y * cos(angle * index))

    if x < 0 or x >= size_x:
        x = x % size_x
    if y < 0 or y >= size_y:
        y = y % size_y

    for p: BasePlayer in GameController.PlayerNodes.get_children():
        if p.player_spawn == selected:
            return _work_position()  
#endregion
    return Vector2(x, y)
    
