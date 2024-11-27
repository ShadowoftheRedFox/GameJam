class_name MultiplayerServer
extends Node

var server_port: int = 8080
var server_ip: String = "127.0.0.1"

signal player_connected
signal player_diconnected
signal host_created
signal connected_to_host

@export var MAX_PLAYER: int = 2

# generate peer instance
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
# the scene loaded when a player joins
@export var player_scene: PackedScene
# the node containing all player connected on host
var players_on_host: Node2D

func change_port(text: String):
	# check validity of new port
	if text.is_valid_int() and int(text) > 0 and int(text) <= 65535 :
		server_port = int(text)

func change_ip(text: String):
	# check validity of new ip (IPv4 or IPv6)
	if text.is_valid_ip_address() :
		server_ip = text

func create_host() -> void:
	var error = peer.create_server(server_port, MAX_PLAYER) # Creation du serveur qui retourne une erreur
	match(error):
		OK: # Le serveur a bien été crée
			print("The server was created!")
		ERR_ALREADY_IN_USE: # Le port ne peut pas être attribué
			push_warning("The server has already been created!")
		ERR_CANT_CREATE: # Erreur dans la création 
			printerr("Could not create the server!")
			return
	
	# set own peer as multiplayer host (if changed to null, host deconnect)
	multiplayer.multiplayer_peer = peer
	
	# add listener for connection and deconnection of others
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(delete_player)
	
	players_on_host = get_tree().current_scene.get_node("Players")
	
	# add a player character for the host
	host_created.emit()
	add_player()
	
func join_server() -> void:
	# instanciate a peer
	peer.create_client(server_ip, server_port)
	multiplayer.multiplayer_peer = peer
	connected_to_host.emit()
	
func add_player(id: int = 1) -> void:
	# check if current user is the host
	if multiplayer.is_server():
		var player = player_scene.instantiate()
		# On attribue un id au joueur (ici le nom du noeud mais cela pourrait être l'attribut d'une classe
		player.name = str(id)
		# On ajoute le joueur à un moment où aucun autre code ne s'execute pour éviter des bugs
		players_on_host.call_deferred("add_child", player)
	else:
		player_connected.emit()
	print("New peer connected : ", id)
	
func delete_player(id: int) -> void:
	var leaving_player = players_on_host.get_node(str(id))
	leaving_player.queue_free()
	player_diconnected.emit()
