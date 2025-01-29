extends Control

const LobbyPreview = preload("res://scenes/UI/Main/Multiplayer/LobbyRoom.tscn")

signal back_pressed

var displayed_room_ip: Array[String] = []
var displayed_room_data: Array[NetworkData] = []

@onready var container: MarginContainer = $MarginContainer/VBoxContainer/Panel/ScrollContainer/RoomContainer
@onready var error: Label = $MarginContainer/VBoxContainer/SubMenu/Error

var private_code_invalid: bool = true

func _ready() -> void:
    Server.Network.discovered.connect(lobby_discovered)

func _on_visibility_changed() -> void:
    if !is_node_ready():
        return

    if visible:
        Server.Network.start_broadcast.emit()
    else:
        Server.Network.stop_broadcast.emit()
        for c in container.get_children():
            c.queue_free()
        displayed_room_ip = []
        displayed_room_data = []

func lobby_discovered(ip: String, data: NetworkData) -> void:
    print("discovered: ", ip, data)
    # TODO add lobby room to container
    # and check if new one isn't already present

func _on_back_pressed() -> void:
    back_pressed.emit()

func _on_line_edit_text_submitted(new_text: String) -> void:
    if new_text.is_empty():
        if private_code_invalid:
            error.text = ""
            private_code_invalid = false
        return
    
    for room in displayed_room_data:
        if room.private == new_text:
            # TODO join a hidden room is code is equal to private
            return
    error.text = "Pas de salle trouvée pour ce code"
    private_code_invalid = true
