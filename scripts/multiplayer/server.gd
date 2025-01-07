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
var peer: ENetMultiplayerPeer = null

signal player_connected(id:int)
signal player_disconnected(id:int)
signal server_connection_failed

# just a handy function, print message preceded by the peer id
enum MessageType {
    PRINT = 0,
    RICH = 1,
    VERBOSE = 2,
    ERR = 3,
    RAW = 4,
    PUSHERR = 5,
    PUSHWARN = 6,
    DEBUG = 7
}
func peer_print(message_type: MessageType, message: String) -> void:
    var id = str(multiplayer.get_unique_id())
    if id == "1":
        id = "Host"

    match (message_type):
        MessageType.RICH:
            print_rich(id + ": " + message)
        MessageType.VERBOSE:
            print_verbose(id + ": " + message)
        MessageType.ERR:
            printerr(id + ": " + message)
        MessageType.RAW:
            printraw(id + ": " + message)
        MessageType.PUSHERR:
            push_error(id + ": " + message)
        MessageType.PUSHWARN:
            push_warning(id + ": " + message)
        MessageType.DEBUG:
            print_debug(id + ": " + message)
        MessageType.PRINT, _:
            print(id + ": " + message)

func peer_connected(id: int) -> void:
    peer_print(MessageType.PRINT, "Player " + str(id) + " connected")
    player_connected.emit(id)
    
func peer_disconnected(id: int) -> void:
    peer_print(MessageType.PRINT, "Player " + str(id) + " disconnected")
    player_disconnected.emit(id)
    # if the server has disconnected
    if id == 1:
        GameController.stop_game()
    
func connection_failed() -> void:
    push_error("Connection failed")
    multiplayer_active = false
    server_connection_failed.emit()


func connected_to_server() -> void:
    peer_print(MessageType.PRINT, "connected to server")
    # send the client data to host, id=1 is host
    var data = PlayerData.new()
    data.id = multiplayer.get_unique_id()
    #data.name = SaveController.parameters.Multiplayer.name
    data.name = str(multiplayer.get_unique_id())
    data.color = SaveController.parameters.Multiplayer.color
    
    MultiplayerController.send_player_infos.rpc_id(1, str(data))


func change_port(text: String):
    # check validity of new port
    if text.is_valid_int() and int(text) > 0 and int(text) <= 65535:
        server_port = int(text)


func change_ip(text: String):
    # check validity of new ip (IPv4 or IPv6)
    if text.is_valid_ip_address() :
        server_ip = text


func change_max_player(text: String):
    # check validity of new max player
    if text.is_valid_int() and int(text) >= 2 and int(text) <= 4095:
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
    
    # set own peer as multiplayer host
    multiplayer.set_multiplayer_peer(peer)
    
    # to differentiate between solo server and mutiplayer ones
    multiplayer_active = !is_solo
    solo_active = is_solo
    
    # host and clients
    multiplayer.peer_connected.connect(peer_connected)
    multiplayer.peer_disconnected.connect(peer_disconnected)
        
    # server ready at that point
    if is_solo:
        print("Server ready")
    else:
        print("Server ready, awaiting for players")
        
    # send info for our own peer
    var data = PlayerData.new()
    data.id = multiplayer.get_unique_id()
    data.name = SaveController.parameters.Multiplayer.name
    #data.name = str(multiplayer.get_unique_id())
    data.color = SaveController.parameters.Multiplayer.color
    
    MultiplayerController.send_player_infos(str(data))
    
    return true
    

# fires only on client when join host
func join_server() -> bool:
    # instanciate a peer
    peer = ENetMultiplayerPeer.new()
    if peer.create_client(server_ip, server_port) != OK:
        peer.close()
        return false
    
    if compressed_data == true:
        peer.host.compress(compression_method)
    
    multiplayer.set_multiplayer_peer(peer)
    multiplayer_active = true
    
    # host and clients
    multiplayer.peer_connected.connect(peer_connected)
    multiplayer.peer_disconnected.connect(peer_disconnected)
    
    # only clients
    multiplayer.connection_failed.connect(connection_failed)
    multiplayer.connected_to_server.connect(connected_to_server)
    multiplayer.server_disconnected.connect(GameController.stop_game)
    
    peer_print(MessageType.PRINT, "Peer connected to host")
    return true
    
func stop_server() -> void:
    # deconnection from server
    print("Stopping server...")
    multiplayer_active = false
    solo_active = false
    
    # since they're being sent twice with ready with the same callable
    # but when set once with host and join, generate errors after relaunch :/
    GameController.Utils.remove_signal_listener(multiplayer.peer_connected)
    GameController.Utils.remove_signal_listener(multiplayer.peer_disconnected)
    GameController.Utils.remove_signal_listener(multiplayer.connection_failed)
    GameController.Utils.remove_signal_listener(multiplayer.connected_to_server)
    GameController.Utils.remove_signal_listener(multiplayer.server_disconnected)
    
    if multiplayer.is_server():
        for connected_peer in multiplayer.get_peers():
            if connected_peer != 1:
                multiplayer.multiplayer_peer.disconnect_peer(connected_peer)
        multiplayer.multiplayer_peer.close()
    else:
        multiplayer.multiplayer_peer.close()
