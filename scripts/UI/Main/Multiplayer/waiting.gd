extends Control

signal back_pressed
var players_waiting: Array[int] = []

func _ready() -> void:
    Server.player_disconnected.connect(remove_player)
    MultiplayerController.player_infos.connect(display_player)
    MultiplayerController.game_starting.connect(reset_menu)

func _on_back_pressed() -> void:
    back_pressed.emit()
    # remove waiting player
    remove_all_players()
    # disconnect from server
    GameController.stop_game()

func reset_menu() -> void: 
    back_pressed.emit()
    # remove waiting player
    remove_all_players()

func _on_start_pressed() -> void:
    # start game and everything for everyone
    if multiplayer.is_server():
        MultiplayerController.start_game.rpc()
    
func display_player(player_data: Dictionary) -> void:
    if players_waiting.has(player_data.id):
        return
    
    var label: Label = Label.new()
    label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    label.name = str(player_data.id)
    label.text = player_data.name
    
    $VBoxContainer/PlayerList.add_child(label)
    players_waiting.append(player_data.id)
    update_buttons()

func remove_player(id: int) -> void:
    # host has disconnected
    if id == 1:
        remove_all_players()
        back_pressed.emit()
    if $VBoxContainer/PlayerList.has_node(str(id)) == true:
        $VBoxContainer/PlayerList.get_node(str(id)).queue_free()
        players_waiting.erase(id)
        update_buttons()

func remove_all_players() -> void:
    for label in $VBoxContainer/PlayerList.get_children():
        label.queue_free()
    players_waiting = []
    update_buttons()


func _on_visibility_changed() -> void:
    if is_node_ready():
        update_buttons()
        
func update_buttons() -> void:
    
    if multiplayer.multiplayer_peer != null and multiplayer.is_server():
        if GameController.Players.size() < 2:
            $VBoxContainer/Actions/Start.disabled = true
            $VBoxContainer/Actions/Start.text = "Il faut au moins 2 joueurs pour commencer"
        else:
            $VBoxContainer/Actions/Start.disabled = false
            $VBoxContainer/Actions/Start.text = "Commencer la partie"
    else:
        $VBoxContainer/Actions/Start.disabled = true
        $VBoxContainer/Actions/Start.text = "Seul l'hôte peut commencer la partie"
