class_name NetworkBroadCaster
extends Node

var broadcast_port = 24520
var udp: PacketPeerUDP = null

var broadcast_data: NetworkData = NetworkData.new() 
const BroadCastTimeout: float = 5.0
const DiscoverTimeout: float = 1.0
var current_timout: float = 0

var _broadcast_host: bool = false
var _broadcast_peer: bool = false

signal discovered(ip: String, data: NetworkData)
signal stop_broadcast()
signal start_broadcast(host: bool)
signal udp_clear

var worker_thread: Thread = Thread.new()

func _ready() -> void:
    stop_broadcast.connect(_stop)
    start_broadcast.connect(_start)

func _stop() -> void:
    if _broadcast_host:
        _broadcast_host = false
        print("Broadcast host stopped")
    if _broadcast_peer:
        _broadcast_peer = false
        print("Broadcast peer stopped")
    
    current_timout = 0

func _start(host: bool = false) -> void:
    _stop()
    if udp:
        await udp_clear
    if host:
        _start_broadcast()
    else:
        _discover_broadcast()

func _process(delta: float) -> void:
    if !_broadcast_host and !_broadcast_peer:
        if udp:
            udp.close()
            udp = null
            udp_clear.emit()
        return
        
    if _broadcast_host:
        # look for timeout
        if current_timout <= 0:
            current_timout = BroadCastTimeout
            # update info
            broadcast_data.update_from_server()
            
            if !worker_thread.is_alive():
                if worker_thread.is_started():
                    worker_thread.wait_to_finish()
                worker_thread.start(_brute.bind(_filtered_ips(), str(broadcast_data)))
                print("started iteration")
            else:
                print("skipped iteration")
        else:
            current_timout -= delta
    
    if _broadcast_peer:
        # look for timeout
        if current_timout <= 0:
            current_timout = BroadCastTimeout
            if udp.get_available_packet_count() > 0:
                var packet = udp.get_packet().get_string_from_utf8()
                print(packet)
                if packet.begins_with(broadcast_data.UniqueSHA):
                    #var server_port = broadcast_port
                    var server_ip = udp.get_packet_ip()
                    #print("Found server at", server_ip, ":", server_port)
                    var data = NetworkData.new()
                    if data.parse(packet):
                        #print("packet valid")
                        discovered.emit(server_ip, data)
                    #else:
                        #print("packet invalid")
        else:
            current_timout -= delta

func _brute(ips: Array[String], packet: String) -> Error:
    for ip in ips:
        var parts := ip.split(".")
        # looks like only those 4 zones where broadcast is detected on windows: range(8, 12)
        # on linux, it's other zones, so broadcast everywhere and hope for the best
        for i in 256: 
            parts[3] = str(i)
            var broadcasted_ip: String = ".".join(parts)
            if _broadcast_host and udp:
                udp.set_dest_address(broadcasted_ip, broadcast_port)
                udp.put_packet(packet.to_utf8_buffer())
            else:
                udp.close()
                udp = null
                udp_clear.emit.call_deferred()
                return OK
    return OK

func _filtered_ips() -> Array[String]:
    var res: Array[String] = []
    for ip in IP.get_local_addresses():
        if ip != "127.0.0.1" and !ip.contains(":"):
            res.append(ip)
    return res

func _start_broadcast() -> void:
    if udp:
        await udp_clear
    if udp:
        printerr("udp should really be cleared now")
    
    udp = PacketPeerUDP.new()
    udp.set_broadcast_enabled(true)
    var err := udp.bind(broadcast_port)
    
    if err != OK:
        printerr("Error while binding udp host: ", error_string(err))
        return
    
    if !udp.is_bound():
        printerr("Udp host is not bound")
        return
    
    print("Broadcasting")
    _broadcast_host = true


func _discover_broadcast() -> void:
    if udp:
        await udp_clear
    if udp:
        printerr("udp should really be cleared now")
    
    udp = PacketPeerUDP.new()
    var err := udp.bind(broadcast_port, "0.0.0.0")
    if err != OK:
        printerr("Error while binding udp peer: ", error_string(err))
        return
    
    if !udp.is_bound():
        printerr("Udp peer is not bound")
        return
    
    print("Searching for rooms...")
    _broadcast_peer = true
