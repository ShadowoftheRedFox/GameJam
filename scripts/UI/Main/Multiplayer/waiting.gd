extends Control

signal back_pressed

func _ready() -> void:
    print("Listening for server")
    Server.player_connected.connect(display_player_waiter, CONNECT_PERSIST)
    Server.player_disconnected.connect(remove_player, CONNECT_PERSIST)

func _on_back_pressed() -> void:
    back_pressed.emit()
    # disconnect from server
    Server.disconnect_server()

func _on_start_pressed() -> void:
    # TODO start game and everything for everyone
    GameController.start_game()
    pass

func display_player_waiter(id: int) -> void:
    # we know a signal is incoming
    MultiplayerController.player_infos.connect(display_player.bind(id))
    print("Waiting for infos")
    
func display_player(id: int) -> void:
    #if !GameController.game_started: 
    #    return
        
    var label: Label = Label.new()
    var player_data: Dictionary = GameController.Players.get(id, {})
    label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    label.name = player_data.name
    label.text = player_data.name
    
    $VBoxContainer/PlayerList.add_child(label)

func remove_player(id: int) -> void:
    var player_data: Dictionary = GameController.Players.get(id, {})
    if player_data.has("name"):
        var label: Label = $VBoxContainer/PlayerList.get_node(player_data.name)
        label.queue_free()
