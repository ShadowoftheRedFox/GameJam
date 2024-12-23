class_name MultiplayerServer
extends Node

# TODO password protected server?

var server_port: int = 8080
var server_ip: String = "127.0.0.1"
var server_max_player: int = 2

var multiplayer_active: bool = false
var solo_active: bool = false

# to compress transmitted data
var compressed_data: bool = false
var compression_method: ENetConnection.CompressionMode = ENetConnection.COMPRESS_RANGE_CODER

# generate peer instance
var peer: ENetMultiplayerPeer
# the scene loaded when a player joins
var player_scene: PackedScene = load("res://scenes/entities/Player.tscn")

signal player_connected(id:int)
signal player_disconnected(id:int)

func _ready() -> void:
    # add listener for connection and deconnection of others
    
    # host and clients
    multiplayer.peer_connected.connect(peer_connected)
    multiplayer.peer_disconnected.connect(peer_disconnected)
    
    # only clients
    multiplayer.connection_failed.connect(connection_failed)
    multiplayer.connected_to_server.connect(connected_to_server)

func peer_connected(id: int) -> void:
    print(multiplayer.get_unique_id(), ": Player ", id, " connected")
    player_connected.emit(id)
    pass
    
    
func peer_disconnected(id: int) -> void:
    print(multiplayer.get_unique_id(), ": Player ", id, " disconnected")
    player_disconnected.emit(id)
    pass
    
func connection_failed() -> void:
    print(multiplayer.get_unique_id(), ": connection failed")
    multiplayer_active = false


func connected_to_server() -> void:
    print(multiplayer.get_unique_id(), ": connected to server")
    # send the client data to host, id=1 is host
    MultiplayerController.send_player_infos.rpc_id(1, {
        "id": multiplayer.get_unique_id(),
        #"name": SaveController.parameters.Multiplayer.name,
        "name": str(multiplayer.get_unique_id()),
        "color": SaveController.parameters.Multiplayer.color,
        "score": 0
    })


func change_port(text: String):
    # check validity of new port
    if text.is_valid_int() and int(text) > 0 and int(text) <= 65535:
        server_port = int(text)


func change_ip(text: String):
    # check validity of new ip (IPv4 or IPv6)
    if text.is_valid_ip_address() :
        server_ip = text


func change_max_player(text: String):
    # check validity of new ip (IPv4 or IPv6)
    if text.is_valid_int() and int(text) >= 2:
        server_max_player = int(text)


func create_host(is_solo: bool = false) -> bool:
    # since solo games is a self host server of 1
    peer = ENetMultiplayerPeer.new()
    var max_player = server_max_player
    if is_solo == true:
        max_player = 1
    
    # server creation
    var error = peer.create_server(server_port, max_player) 
    match(error):
        OK: # server correctly created
            print("The server was created!")
        ERR_ALREADY_IN_USE: # port can not be attributed
            push_warning("The server has already been created!")
        ERR_CANT_CREATE: # error while creating
            push_error("Could not create the server!")
            return false
        _: # handling others
            push_error("Error while creating server: ", error)
            return false
    
    # compress packets if we want
    if compressed_data == true:
        peer.host.compress(compression_method)
    
    # set own peer as multiplayer host (if changed to null, host deconnect)
    multiplayer.set_multiplayer_peer(peer)
    
    # to differentiate between solo server and mutiplayer ones
    multiplayer_active = !is_solo
    solo_active = is_solo
    
    # server ready at that point
    print("Server ready, awaiting for players")
    # start game for host
    #GameController.start_game()
    # add a player character for the host
    MultiplayerController.send_player_infos({
        "id": multiplayer.get_unique_id(),
        #"name": SaveController.parameters.Multiplayer.name,
        "name": str(multiplayer.get_unique_id()),
        "color": SaveController.parameters.Multiplayer.color,
        "score": 0
    })
    
    return true
    

# fires only on client when join host
func join_server() -> bool:
    # instanciate a peer
    peer = ENetMultiplayerPeer.new()
    if peer.create_client(server_ip, server_port) != OK:
        return false
    
    if compressed_data == true:
        peer.host.compress(compression_method)
    
    multiplayer.multiplayer_peer = peer
    multiplayer_active = true
    
    #connected_to_host.emit()
    #GameController.start_game()
    print("Peer connected to host: ", multiplayer.get_unique_id())
    return true
    
func disconnect_server() -> void:
    # TODO deconnection from server
    multiplayer_active = false
    solo_active = false
    if multiplayer.is_server():
        pass
    else:
        pass
