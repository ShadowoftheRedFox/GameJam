class_name SpectatorMenu
extends Control

@onready var spectate: HBoxContainer = $CanvasLayer/MarginContainer/Spectate
@onready var players_options: OptionButton = $CanvasLayer/MarginContainer/Spectate/Players
@onready var score: MarginContainer = $CanvasLayer/MarginContainer/Scores

var player_spectating_id: int = 0

func _ready() -> void:
    Game.player_infos_update.connect(update_player_list)
    Server.player_disconnected.connect(remove_player)
    update_player_list(null)
    focus_on_player.call_deferred()
    
func update_player_list(_data: PlayerData) -> void:
    # add every player in the list
    var players := Game.Players.list
    for player in players:
        if !player.is_spectator:
            players_options.add_item(player.name, player.id)
        else:
            # add spectator as disabled
            players_options.add_item(player.name, player.id)
            players_options.set_item_disabled(players_options.item_count - 1, true)
    
    if players_options.item_count > 0:
        # when it's our first focus, focus on first in the list
        # or our previously focused player has been removed
        if player_spectating_id == 0 or !Game.Players.has_player(player_spectating_id):
            focus_on_player()

func remove_player(id: int) -> void: 
    players_options.remove_item(players_options.get_item_index(id))

func _on_before_pressed() -> void:
    if players_options.selected == -1:
        players_options.select(0)
    elif players_options.selected == 0:
        players_options.select(players_options.item_count - 1)
    else:
        players_options.select(players_options.selected - 1)
    
    var id = players_options.get_item_id(players_options.selected)
    var id_data := Game.Players.get_player(id)
    if id_data and id_data.is_spectator:
        _on_before_pressed()
        return
    
    focus_on_player()

func _on_after_pressed() -> void:
    if players_options.selected == -1:
        players_options.select(players_options.item_count - 1)
    elif players_options.selected == players_options.item_count - 1:
        players_options.select(0)
    else:
        players_options.select(players_options.selected + 1)
        
    var id = players_options.get_item_id(players_options.selected)
    var id_data := Game.Players.get_player(id)
    if id_data and id_data.is_spectator:
        _on_after_pressed()
        return
    
    focus_on_player()

func _on_players_item_selected(_index: int) -> void:
    focus_on_player()

func focus_on_player() -> void:
    # clear listeners
    var player: BasePlayer = null
    if player_spectating_id != 0:
        if Game.Players.has_pnode(player_spectating_id):
            player = Game.Players.get_pnode(player_spectating_id)
            Game.Utils.remove_signal_listener(player.room_changed)
            player.camera.disable_camera()
            player = null
    
    # if none selected, select the first one
    if players_options.selected == -1:
        players_options.select(0)
        
    # get our focused player id 
    player_spectating_id = players_options.get_item_id(players_options.selected)
    # what it does: move to the room of the player
    # listen if changing room
    # connect to it's camera, or own camera follows him
    var player_data = Game.Players.get_player(player_spectating_id)
    if Game.Players.has_pnode(player_spectating_id):
        player = Game.Players.get_pnode(player_spectating_id)
        player.room_changed.connect(follow_camera)
        player.camera.enabled = true
        
    if player_data == null or player == null:
        return
    
    # set this player as the main instance
    Game.main_player_instance = player
    Game.current_room = Game.current_map[player.player_room.y][player.player_room.x]

func follow_camera() -> void:
    if Game.Players.has_pnode(player_spectating_id):
        var player: BasePlayer = Game.Players.get_pnode(player_spectating_id)
        Game.current_room = Game.current_map[player.player_room.y][player.player_room.x]
        player.camera.snap()
        player.camera.set_limits(Game.current_room.Map)

func _on_spectate_pressed() -> void:
    if spectate.visible:
        spectate.hide()
    else:
        spectate.show()
    score.hide()

func _on_score_pressed() -> void:
    if score.visible:
        score.hide()
    else:
        score.show()
    spectate.hide()


func _on_quit_pressed() -> void:
    Game.stop_game()
