extends Node

@rpc("any_peer", "call_local")
func send_player_infos(data: Dictionary) -> void:
    if !Server.multiplayer_active:
        push_warning("Trying to send player info when no server active")
        return
    
    if !data.has("id"):
        printerr("Connected instances did not gives any id!")
        return
    
    if !GameController.Players.has(data.get("id", 0)):
        GameController.Players.get_or_add(data.get("id"), data)
        
    # update all connected peers with the new data
    if multiplayer.is_server():
        for i in GameController.Players:
            send_player_infos.rpc(GameController.Players.get(i, {}))
