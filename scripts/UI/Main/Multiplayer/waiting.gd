extends Control

signal back_pressed
var players_waiting: Array[int] = []
var players_ready: Array[int] = []
var just_pressed = true

func _ready() -> void:
    Server.player_disconnected.connect(remove_player)
    Server.server_connection_failed.connect(connection_failed)
    GameController.player_infos_update.connect(display_player)
    GameController.game_starting.connect(reset_menu)
    GameController.spectator_update.connect(update_spectator)
    GameController.lobby_ready.connect(lobby_readying)

func lobby_readying(id: int) -> void:
    players_ready.append(id)
    update_buttons()

func _on_back_pressed() -> void:
    back_pressed.emit()
    reset_menu()
    # remove waiting player
    remove_all_players()
    # disconnect from server
    GameController.stop_game(true)

func reset_menu() -> void:
    $VBoxContainer/Actions/Start.text = "Connection en cours..."
    just_pressed = true
    back_pressed.emit()
    # remove waiting player
    remove_all_players()

func _on_start_pressed() -> void:
    # start game and everything for everyone
    if multiplayer.is_server():
        MultiplayerController.start_game.rpc()
    
func display_player(player_data: PlayerData) -> void:
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
        back_pressed.emit()
        reset_menu()
    if $VBoxContainer/PlayerList.has_node(str(id)):
        $VBoxContainer/PlayerList.get_node(str(id)).queue_free()
        players_waiting.erase(id)
        players_ready.erase(id)
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
    $Spectator.show()
    if multiplayer.is_server():
        if players_waiting.size() < 2:
            $VBoxContainer/Actions/Start.disabled = true
            $VBoxContainer/Actions/Start.text = "Il faut au moins 2 joueurs pour commencer"
        elif players_ready.size() != players_waiting.size():
            $VBoxContainer/Actions/Start.disabled = true
            $VBoxContainer/Actions/Start.text = "Tout le monde n'a pas fini de charger"
        else:
            $VBoxContainer/Actions/Start.disabled = false
            $VBoxContainer/Actions/Start.text = "Commencer la partie"
    else:
        # there is a bug, where if you try to connect to server less host
        # it takes the timeout (30s) before sending connection failed
        # with this, it wait for the first update before saying anything else
        $VBoxContainer/Actions/Start.disabled = true
        if !just_pressed:
            $VBoxContainer/Actions/Start.text = "Seul l'hôte peut commencer la partie"
    just_pressed = false

func update_spectator(id: int) -> void:
    if $VBoxContainer/PlayerList.has_node(str(id)) and GameController.Players.has_player(id):
        var text = GameController.Players.get_player(id).name
        if GameController.Players.get_player(id).is_spectator:
            text += " (Spectateur)"
        $VBoxContainer/PlayerList.get_node(str(id)).text = text
    update_buttons()

func connection_failed() -> void:
    $VBoxContainer/Actions/Start.text = "Connection impossible, veuillez réessayer"


func _on_spectator_toggled(toggled_on: bool) -> void:
    MultiplayerController.update_spectator.rpc(multiplayer.get_unique_id(), toggled_on)
