extends Control

@onready var lobby_name: LineEdit = $VBoxContainer/Name/LineEdit
@onready var max_players: LineEdit = $VBoxContainer/MaxPlayers/LineEdit
@onready var save_selector: OptionButton = $VBoxContainer/Save/OptionButton
@onready var password: LineEdit = $VBoxContainer/Password/LineEdit
@onready var public_room: CheckButton = $VBoxContainer/Public/CheckButton
@onready var host: Button = $VBoxContainer/Host
@onready var error: Label = $VBoxContainer/Error

var name_valid: bool = true
var max_players_valid: bool = true
var save_valid: bool = false

signal host_pressed

func _ready() -> void:
    Save.saves_changed.connect(check_save)
    check_save()

func check_save() -> void:
    # remove everything
    save_selector.clear()
    if len(Save.save_names) > 0:
        var i = 0
        for save_name in Save.save_names:
            save_selector.add_item(save_name, i)
            i += 1
        # enable other buttons
        save_valid = true
    else:
        save_selector.add_item("LabHyrinTical", 0)
        save_selector.set_item_disabled(0, true)
        # disable other buttons
        save_valid = false

func global_change() -> void:
    host.disabled = !(name_valid and max_players_valid and save_valid) 
    if !name_valid:
        error.text = "Vous devez avoir un nom de salle valide"
        return
    if !max_players_valid:
        if !max_players.text.is_valid_int():
            error.text = "Vous devez rentrer un nombre valide pour le max. de joueurs"
        elif int(max_players.text) < 2 or int(max_players.text) > Server.ABS_MAX_PLAYER:
            error.text = "Vous devez mettre un nombre max. de joueurs entre 2 et " + str(Server.ABS_MAX_PLAYER)
        return
    if !save_valid:
        error.text = "Choisissez une sauvegarde"
        return
        
    error.text = ""
    
    Server.server_name = lobby_name.text
    Server.server_public = public_room.button_pressed
    Server.server_password_protected = !password.text.is_empty()
    Server.server_password = password.text
    Server.server_code = Game.Utils.random_str(8)
    Server.change_max_player(max_players.text)
    
func _on_name_changed(new_text: String) -> void:
    if new_text.is_empty():
        name_valid = false
    else:
        name_valid = true
    global_change()

func _on_max_player_changed(new_text: String) -> void:
    max_players_valid = new_text.is_valid_int() and int(new_text) >= 2 and int(new_text) <= Server.ABS_MAX_PLAYER
    global_change()

func _on_password_changed(_new_text: String) -> void:
    global_change()

func _on_host_pressed() -> void:
    global_change()
    if host.disabled:
        return
    Game.launch_multiplayer(save_selector.get_item_text(save_selector.selected))
    host_pressed.emit()
    hide()
    Server.Network.start_broadcast.emit(true)
