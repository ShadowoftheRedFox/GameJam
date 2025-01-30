class_name NetworkData

## if by any chance something is also sending packets on the port, ours starts with this
const UniqueSHA = "a9aaab6446c29f26347454c1bd1fa8c7f3fa4be4337d1248e69ca743d1fdb19b"

var lobby_name: String = "Emilie"
var max_player: int = 5
var current_player: int = 1
var game_mode: Game.GameModes = Game.GameModes.Classic
# visible on broadcast
var private: String = ""
# need password
var protected: bool = false

func update_from_server() -> void:
    max_player = Server.server_max_player
    current_player = Server.current_player
    private = Server.server_code if Server.server_public else ":" + Server.server_code
    protected = Server.server_password_protected
    game_mode = Game.hosted_gamemode

func equal(data: NetworkData) -> bool:
    return lobby_name == data.lobby_name            and \
            max_player == data.max_player           and \
            current_player == data.current_player   and \
            game_mode == data.game_mode             and \
            private == data.private                 and \
            protected == data.protected  

func parse(string: String) -> bool:
    if !string.begins_with(UniqueSHA + ":"):
        return false
    var var_data = JSON.parse_string(string.trim_prefix(UniqueSHA + ":"))
    if typeof(var_data) != TYPE_DICTIONARY:
        return false
    
    var data: Dictionary = (var_data as Dictionary)
    lobby_name = str(data.get_or_add("name", "Emilie"))
    max_player = int(data.get_or_add("max", 1))
    current_player = int(data.get_or_add("players", 1))
    @warning_ignore("int_as_enum_without_cast")
    game_mode = (data.get_or_add("mode", Game.GameModes.Classic))
    private = data.get_or_add("private", "")
    protected = bool(data.get_or_add("protected", 1))
    IP.get_local_addresses()
    return true

func _to_string() -> String:
    return UniqueSHA + ":" + JSON.stringify({
        "name": lobby_name,
        "max": max_player,
        "players": current_player,
        "mode": int(game_mode),
        "private": private,
        "protected": int(protected)
    })
