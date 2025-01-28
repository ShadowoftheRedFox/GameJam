extends Node

var broadcast_port = 12345
var udp_broadcaster : PacketPeerUDP
var udp_listener : PacketPeerUDP
var found_server = false
var peer

func _start_broadcasting() -> void:
    var broadcast_address_list = get_broadcast_addresses()
    while true:
        for broadcast_address in broadcast_address_list:
            #var broadcast_address = "192.168.114.255" #en principe c'est toujours cette adresse
            #sinon, l'adresse de "bradcast" dépend du masque de sous réseau
            var packet = "GODOT_SERVER:" + str(broadcast_address)
            udp_broadcaster.set_dest_address(broadcast_address, broadcast_port)
            udp_broadcaster.put_packet(packet.to_utf8_buffer())
            await  get_tree().create_timer(1.0).timeout

func _discover_servers() -> void:
    print("Searching for servers...")
    while true:
        if udp_listener.get_available_packet_count() > 0:
            var packet = udp_listener.get_packet().get_string_from_utf8()
            if packet.begins_with("GODOT_SERVER:"):
                var server_port = broadcast_port
                var server_ip = udp_listener.get_packet_ip()
                print("Found server at", server_ip, ":", server_port)
                
                #se connecter au serveur détecté
                peer = ENetMultiplayerPeer.new()
                peer.create_client(server_ip, server_port)
                multiplayer.multiplayer_peer = peer
                peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
                #add_player(multiplayer.get_unique_id()) -> fonction qui ajoute le joueur
                break
        await get_tree().create_timer(0.1).timeout # Vérifie les paquets toutes les 100 ms


func host() -> void:
    peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(broadcast_port)
    if error != OK:
        printerr("cannot host:",error)
        return
    
    peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
    multiplayer.multiplayer_peer = peer
    
    udp_broadcaster = PacketPeerUDP.new()
    udp_broadcaster.set_broadcast_enabled(true)
    udp_broadcaster.bind(broadcast_port)
    call_deferred("_start_broadcasting")
    
    #add_player(multiplayer.get_unique_id())
    
func join() -> void:
    var bind_address = "*"
    udp_listener = PacketPeerUDP.new()
    var error = udp_listener.bind(broadcast_port, bind_address)
    print(error)
    _discover_servers()


#renvoie la liste des adresses IP locales et de leurs masque de sous réseau
func get_masknadress() -> Array:
    var output_ip = []
    var output_mask = []
    # Exécute la commande système appropriée en fonction de l'OS
    if OS.get_name() == "Windows":
        OS.execute("CMD.exe", ["/C", "ipconfig | findstr /R IPv4"], output_ip)
        OS.execute("CMD.exe", ["/C", "ipconfig | findstr /R Mask"], output_mask)
    
    var pattern = r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
    var regex = RegEx.new()
    regex.compile(pattern)
    
    var matches = regex.search_all(output_ip[0])
    var ip_addresses = []
    var subnet_mask = []
    
    for match in matches:
        ip_addresses.append(match.get_string())
    
    matches = regex.search_all(output_mask[0])
    for match in matches:
        subnet_mask.append(match.get_string())
        
    return([ip_addresses, subnet_mask])

#renvoie la liste des adresses de broadcast
func get_broadcast_addresses() -> Array:
    var broadcast_addresses = []
    var list = get_masknadress()
    
    var ip_address = list[0]
    var subnet_mask = list[1]

    for i in range(len(ip_address)):
        if ip_address[i] != "" and subnet_mask[i] != "":
            # Convertit les adresses en formats numériques pour le calcul du broadcast
            var ip_numeric = _ip_to_numeric(ip_address[i])
            var mask_numeric = _ip_to_numeric(subnet_mask[i])
            var broadcast_numeric = ip_numeric | ~mask_numeric
            # Reconvertit en format lisible (IPv4)
            var broadcast_address = _numeric_to_ip(broadcast_numeric)
            broadcast_addresses.append(broadcast_address)
    return broadcast_addresses

# Convertit une adresse IP (en chaîne) en entier numérique
func _ip_to_numeric(ip: String) -> int:
    var parts = ip.split(".")
    return (int(parts[0]) << 24) | (int(parts[1]) << 16) | (int(parts[2]) << 8) | int(parts[3])

# Convertit un entier numérique en adresse IP (en chaîne)
func _numeric_to_ip(numeric: int) -> String:
    return "%d.%d.%d.%d" % [
        (numeric >> 24) & 0xFF,
        (numeric >> 16) & 0xFF,
        (numeric >> 8) & 0xFF,
        numeric & 0xFF]
