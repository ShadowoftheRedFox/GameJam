class_name LobbyRoom
extends MarginContainer

signal join(ip: String, data: NetworkData)

var room_ip: String = ""
var room_data: NetworkData = null

@onready var room_name: Label = $MarginContainer/HBoxContainer/HBoxContainer/Name
@onready var gamemode: Label = $MarginContainer/HBoxContainer/HBoxContainer/Gamemode
@onready var players: Label = $MarginContainer/HBoxContainer/HBoxContainer/Players
@onready var lock: Label = $MarginContainer/HBoxContainer/Lock

func setup(ip: String, data: NetworkData) -> void:
    name = ip
    room_ip = ip
    update(room_ip, data)

func update(ip: String, data: NetworkData) -> void:
    if ip != room_ip:
        return
    
    room_data = data
    
    room_name.text = room_data.lobby_name
    gamemode.text = Game.GameModesNames[room_data.game_mode]
    players.text = str(room_data.current_player) + " / " + str(room_data.max_player)
    visible = !room_data.private.begins_with(":") # visible if private code doesn't start by ":"
    lock.visible = room_data.protected # visible if password required

func _on_join_pressed() -> void:
    join.emit(room_ip, room_data)
