class_name MultiplayerServer
extends Node

# TODO password protected server?

var server_port: int = 8080
var server_ip: String = "127.0.0.1"
var server_max_player: int = 2

var multiplayer_active: bool = false

# to compress transmitted data
var compressed_data: bool = false
var compression_method: ENetConnection.CompressionMode = ENetConnection.COMPRESS_RANGE_CODER

# generate peer instance
var peer: ENetMultiplayerPeer
# the scene loaded when a player joins
var player_scene: PackedScene = load("res://scenes/entities/Player.tscn")
# the node containing all player connected on host
var players_on_host: Node2D 

# gets calls on server and clients 
signal player_connected
signal player_diconnected

# only on host
signal host_created

# only on client
signal connected_to_host


func _ready() -> void:
    # add listener for connection and deconnection of others
    
    # host and clients
    multiplayer.peer_connected.connect(add_player)
    multiplayer.peer_disconnected.connect(delete_player)
    
    # only clients
    multiplayer.connected_to_server.connect(connected_to_server)
    multiplayer.connection_failed.connect(connection_failed)


func connection_failed() -> void:
    print("connection failed")
    multiplayer_active = false


func connected_to_server() -> void:
    print("connected to server")
    # send the client data to host, id=1 is host
    MultiplayerController.send_player_infos.rpc_id(1, {
        "id": multiplayer.get_unique_id(),
        "name": SaveController.parameters.Multiplayer.name,
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
            printerr("Could not create the server!")
            return false
        _: # handling others
            printerr("Error while creating server: ", error)
            return false
    
    # compress packets if we want
    if compressed_data == true:
        peer.host.compress(compression_method)
    
    # set own peer as multiplayer host (if changed to null, host deconnect)
    multiplayer.set_multiplayer_peer(peer)
    
    # server ready at that point
    print("Server ready")
    multiplayer_active = !is_solo
    
    players_on_host = get_tree().current_scene.get_node("Players")
    
    # add a player character for the host
    host_created.emit()
    add_player()
    return true
    

func join_server() -> void:
    # instanciate a peer
    peer = ENetMultiplayerPeer.new()
    peer.create_client(server_ip, server_port)
    
    if compressed_data == true:
        peer.host.compress(compression_method)
    
    multiplayer.multiplayer_peer = peer
    multiplayer_active = true
    
    #connected_to_host.emit()
    GameController.start_game()
    

func add_player(id: int = 1) -> void:
    # check if current user is the host
    #if multiplayer.is_server():
        #var player = player_scene.instantiate()
        ## On attribue un id au joueur (ici le nom du noeud mais cela pourrait être l'attribut d'une classe
        #player.name = str(id)
        ## On ajoute le joueur à un moment où aucun autre code ne s'execute pour éviter des bugs
        #players_on_host.call_deferred("add_child", player)
    #else:
        #player_connected.emit(id)
    print("New peer connected : ", id)
    

func delete_player(id: int) -> void:
    #var leaving_player = players_on_host.get_node(str(id))
    #leaving_player.queue_free()
    player_diconnected.emit(id)
