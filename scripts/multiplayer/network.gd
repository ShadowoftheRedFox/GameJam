class_name NetworkBroadCaster
extends Node

var own_ip: String = "None"

var broadcast_port = 24520
var udp_host: PacketPeerUDP = null
var udp_peer: PacketPeerUDP = null

var broadcast_data: NetworkData = NetworkData.new() 
const BroadCastTimeout: float = 5.0
const DiscoverTimeout: float = 1.0
var current_timout: float = 0

var _broadcast_host: bool = false
var _broadcast_peer: bool = false

signal discovered(ip: String, data: NetworkData)
signal stop_broadcast()
signal start_broadcast(host: bool)
#signal udp_host_clearable

var mutex: Mutex = Mutex.new()

var worker_thread: Thread = Thread.new()

func _ready() -> void:
    stop_broadcast.connect(_stop)
    start_broadcast.connect(_start)
    
    if OS.has_feature("windows"):
        if OS.has_environment("COMPUTERNAME"):
            own_ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)
    elif OS.has_feature("x11"):
        if OS.has_environment("HOSTNAME"):
            own_ip = IP.resolve_hostname(str(OS.get_environment("HOSTNAME")), IP.TYPE_IPV4)
    elif OS.has_feature("OSX"):
        if OS.has_environment("HOSTNAME"):
            own_ip = IP.resolve_hostname(str(OS.get_environment("HOSTNAME")), IP.TYPE_IPV4)
    elif OS.has_feature("linux"):
        var out = []
        OS.execute("bash", ["-c", "hostname -I"], out)
        if out.size() >= 1:
            own_ip = out[0].split(" ")[0]
        
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

    if host:
        _start_broadcast()
    else:
        _discover_broadcast()

func _process(delta: float) -> void:
    if !_broadcast_host and !_broadcast_peer:
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
            mutex.lock()
            if udp_peer.get_available_packet_count() > 0:
                var packet = udp_peer.get_packet().get_string_from_utf8()
                print(packet)
                if packet.begins_with(broadcast_data.UniqueSHA):
                    #var server_port = broadcast_port
                    var server_ip = udp_peer.get_packet_ip()
                    #print("Found server at", server_ip, ":", server_port)
                    var data = NetworkData.new()
                    if data.parse(packet):
                        #print("packet valid")
                        discovered.emit(server_ip, data)
                    #else:
                        #print("packet invalid")
            mutex.unlock()
        else:
            current_timout -= delta

func _brute(ips: Array[String], packet: String) -> Error:
    for ip in ips:
        var parts := ip.split(".")
           
        # we take 0b10000 for 16 possibilities to switch one of 4 parts with 255
        # so i is between 0b10000-1 and 0, we check if the fourth byte is flipped
        # if yes, 255, else normal, and so on
        
        # after testing, it seems only the last two part needs to be swapped, so down to 0b100
        for i: int in 0b100: 
            var broadcasted_ip: String = ".".join([
                parts[0], # if i & 0b1000 != 0 else '255',
                parts[1], #if i & 0b0100 != 0 else '255',
                parts[2] if i & 0b0010 != 0 else '255',
                parts[3] if i & 0b0001 != 0 else '255'
            ])
           
            if _broadcast_host:
                mutex.lock()
                udp_host.set_dest_address(broadcasted_ip, broadcast_port)
                udp_host.put_packet(packet.to_utf8_buffer())
                mutex.unlock()
                #udp_host_clearable.emit.call_deferred()
    return OK

func _filtered_ips() -> Array[String]:
    var res: Array[String] = []
    for ip in IP.get_local_addresses():
        if ip != "127.0.0.1" and !ip.contains(":") and ip != own_ip:
            res.append(ip)
    return res

func _start_broadcast() -> void:
    mutex.lock()
    if udp_host:
        #await udp_host_clearable
        udp_host.close()
        udp_host = null

    if udp_host:
        printerr("udp host should really be cleared now")
    
    udp_host = PacketPeerUDP.new()
    udp_host.set_broadcast_enabled(true)
    var err := udp_host.bind(broadcast_port)
    mutex.unlock()
    
    if err != OK:
        printerr("Error while binding udp host: ", error_string(err))
        return
    
    if !udp_host.is_bound():
        printerr("Udp host is not bound")
        return
    
    print("Broadcasting")
    _broadcast_host = true


func _discover_broadcast() -> void:
    mutex.lock()
    if udp_peer:
        udp_peer.close()
        udp_peer = null
        
    
    if udp_peer:
        printerr("udp peer should really be cleared now")
    
    udp_peer = PacketPeerUDP.new()
    var err := udp_peer.bind(broadcast_port, "0.0.0.0")
    mutex.unlock()
    
    if err != OK:
        printerr("Error while binding udp peer: ", error_string(err))
        return
    
    if !udp_peer.is_bound():
        printerr("Udp peer is not bound")
        return
    
    print("Searching for rooms...")
    _broadcast_peer = true
