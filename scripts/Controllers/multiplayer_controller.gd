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
        
    if !Game.Players.has_player(data.id):
        Game.Players.list.append(data)
        Game.player_infos_update.emit(data)
    
    # update all connected peers with the new data
    if multiplayer.is_server():
        Server.peer_print(Server.MessageType.PRINT, "Sending infos to peers")
        for i in Game.Players.get_players_ids():
            send_player_infos.rpc(str(Game.Players.get_player(i)))
    else:
        Server.peer_print(Server.MessageType.PRINT, "Getting infos from host")

@rpc("authority", "call_local")
func start_game() -> void:
    if Server.solo_active == false and Server.multiplayer_active == false:
        push_warning("Server is not active, can not use 'start_game'")
        return
        
    Server.Network.stop_broadcast.emit()
        
    # add all the scene with their data
    for y in Game.current_map.size():
        for x in Game.current_map[y].size():
            var room: MapRoom = Game.current_map[y][x]
            Game.MapNodes.add_child(room)
            
            var tile_map = room.Map
            var tile_rect = tile_map.get_used_rect()
            var cell_size = tile_map.tile_set.tile_size
            var limit_left = tile_rect.position.x * cell_size.x
            var limit_top = tile_rect.position.y * cell_size.y
            
            room.position.x = x * Game.room_size.x + abs(limit_left)
            room.position.y = y * Game.room_size.y + abs(limit_top)

    # tell our client listeners that the game is starting
    Game.game_starting.emit()
    Game.hide_menu()
    Game.game_started = true
    Game.current_room = Game.current_map[0][0]
    
    # sort in ID order to make sure everyone spawn correctly
    Game.Players.list.sort_custom(func sort_spawn(a: PlayerData, b: PlayerData): return a.id < b.id)
    # spawn all peer instances
    for p in Game.Players.list:
        if !p.is_spectator:
            spawn_player.call_deferred(p)

    # spawn if own is spectator
    if Game.Players.get_player(multiplayer.get_unique_id()).is_spectator:
        Game.MenuNodes.add_child(Game.SpectatorScene.instantiate())

func spawn_player(player_data: PlayerData) -> void:
    if player_data == null:
        push_error("player data is null")
        return
    
    # find a spawn for the player
    var spawn = _work_position()
    var spawn_room: MapRoom = Game.current_map[spawn.y][spawn.x]
    Game.current_room = spawn_room
    
    var currentPlayer: BasePlayer = Game.PlayerScene.instantiate()
    # remember our own player
    if player_data.id == multiplayer.get_unique_id():
        Game.main_player_instance = currentPlayer
    
    # setup everything
    currentPlayer.player_spawn = spawn
    currentPlayer.global_position = spawn_room.PlayerSpawn.global_position
    #currentPlayer.name = str(player_data.id)
    currentPlayer.set_player_name(player_data.name)
    currentPlayer.set_authority(player_data.id)
    
    Game.Players.add_node(player_data.id, currentPlayer)
    currentPlayer.change_room(spawn)
    currentPlayer.disable_others_camera(player_data.id)
    currentPlayer.camera.snap()
    currentPlayer.camera.set_limits(spawn_room.Map)
        
    index += 1
    #Server.peer_print(Server.MessageType.ERR, "New instance of Player: " + str(player_data.id))

@rpc("any_peer", "call_local")
func remove_player(id: int) -> void:
    if !Game.Players.has_player(id):
        return

    if !Game.game_started:
        Game.Players.erase_player(id)
        return
    
    #var player_data = Game.Players.get_player(id)
    if Game.Players.has_node(id):
        Game.Players.get_node(id).queue_free()
    Game.Players.erase_player(id)
    index -= 1
    # no player_infos_update because we should be listening to player disconnect instead

func send_map_data(id: int) -> void:
    if multiplayer.is_server():
        var save = Save.get_save(Game.hosted_save_name)
        # FIXME do not pass whole save if something sensitive is added 
        receive_map_data.rpc_id(id, save[0])

@rpc("call_remote")
func receive_map_data(data: Dictionary) -> void:
    Game.load_game.call_deferred("", data)

@rpc("any_peer", "reliable")
func player_buff_update(id: int, data_raw: String) -> void:
    var data := PlayerData.new(data_raw)
    # TODO tell which buff to remove globally
    if !Game.game_started:
        return
    if !Game.Players.has_player(id):
        push_warning("Updating buff on unknown player")
        return
    
    var player_data := Game.Players.get_player(id)
    player_data.buff = data.buff
    
    var player: BasePlayer = Game.Players.get_node(id)
    player.update_buff(player_data)
    Game.player_infos_update.emit(player_data)

@rpc("any_peer", "call_local")
func update_spectator(id: int, is_spectator: bool) -> void:
    if Game.Players.has_player(id):
        Game.Players.get_player(id).is_spectator = is_spectator
        Game.spectator_update.emit(id)

func _work_position() -> Vector2:
    var size_y = Game.current_map.size()
    var size_x = Game.current_map[0].size()
    
#region Random
    # random
    var selected = Vector2i(Game.rng.randi_range(0, size_x - 1), Game.rng.randi_range(0, size_y - 1))
    for p: BasePlayer in Game.PlayerNodes.get_children():
        if p.player_spawn == selected:
            return _work_position()
    return selected
#endregion
    
#region Repartition
    # repartition
    #var rx = 0
    #var ry = 0
#
    #match index % 4:
        #0:
            #rx = 0 + int(index / 4.0)
            #ry = 0 + int(index / 4.0)
        #1:
            #rx = size_x - 1 + int(index / 4.0) * size_x
            #ry = size_y - 1 + int(index / 4.0) * size_y
        #2:
            #rx = (size_y) * (size_x - 1) - int(index / 4.0) * size_x
            #ry = (size_y) * (size_x - 1) - int(index / 4.0) * size_y
        #3:
            #rx = size_y * size_x - 1 - int(index / 4.0)
            #ry = size_y * size_x - 1 - int(index / 4.0)
    #return Vector2i(rx % size_x, int(ry / size_y))
#endregion
    
#region Matrix
    # matrix
    #var base_x = randi_range(0, size_x - 1)
    #var base_y = randi_range(0, size_y - 1)
    #var angle = deg_to_rad(360.0 / float(Game.Players.get_player_count()))
#
    #var x = int(base_x * cos(angle * index) - base_y * sin(angle * index))
    #var y = int(base_x * sin(angle * index) + base_y * cos(angle * index))
#
    #if x < 0 or x >= size_x:
        #x = x % size_x
    #if y < 0 or y >= size_y:
        #y = y % size_y
#
    #for p: BasePlayer in Game.PlayerNodes.get_children():
        #if p.player_spawn == Vector2i(x, y):
            #return _work_position()
    #return Vector2i(x, y)
#endregion

@rpc("any_peer", "call_local")
func end_game(killerId: int) -> void:
    if Game.game_ended:
        return
    
    Game.game_ended = true
    Game.game_end.emit(killerId)
    print("Game ended!")
    print("Boss killed by ", ("player " + str(killerId)) if killerId != 0 else "a mob " + str(killerId))
