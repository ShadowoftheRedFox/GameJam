extends Control

const LobbyPreview = preload("res://scenes/UI/Main/Multiplayer/LobbyRoom.tscn")

signal back_pressed
signal join_pressed

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
    # if one already here, update it if necessary
    if displayed_room_ip.has(ip):
        if data.equal(displayed_room_data[displayed_room_ip.find(ip)]):
            # no data changes
            return
        # update node
        displayed_room_data[displayed_room_ip.find(ip)] = data
        if !container.has_node(ip):
            printerr("lobby element ", ip, " is not in container")
            return
        container.get_node(ip).update(ip, data)
        return
    # TODO add lobby room to container
    # and check if new one isn't already present
    # add a lobby in the list
    var lobby: LobbyRoom = LobbyPreview.instantiate()
    lobby.name = ip
    lobby.size_flags_horizontal = Control.SIZE_FILL
    lobby.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    container.add_child(lobby)
    lobby.setup(ip, data)
    displayed_room_ip.append(ip)
    displayed_room_data.append(data)
    lobby.join.connect(_join_lobby)

func _join_lobby(ip: String, data: NetworkData) -> void:
    # TODO handle password
    Server.change_ip(ip)
    Server.server_code = data.private.trim_prefix(":")
    if !Game.join_multiplayer():
        printerr("Error while joining multiplayer")
        return
    join_pressed.emit()

func _on_back_pressed() -> void:
    back_pressed.emit()

func _on_line_edit_text_submitted(new_text: String) -> void:
    if new_text.is_empty():
        if private_code_invalid:
            error.text = ""
            private_code_invalid = false
        return
    
    for room in displayed_room_data:
        if room.private == ":" + new_text:
            # join a hidden room is code is equal to private
            _join_lobby(displayed_room_ip[displayed_room_data.find(room)], room)
            return
    error.text = "Pas de salle trouvée pour ce code"
    private_code_invalid = true
