class_name ScoreData

var global: int = 0

var death_amount: int = 0
var player_kill_amount: int = 0
var mob_kill_amount: int = 0
var miniboss_kill_amount: int = 0
var boss_kill_amount: int = 0

var damage_dealt: int = 0
var damage_received: int = 0

var distance_traveled: int = 0
var dashes: int = 0
var jumps: int = 0


func _to_string() -> String:
    return JSON.stringify({
        "global": global,
        "death_amount": death_amount,
        "player_kill_amount": player_kill_amount,
        "mob_kill_amount": mob_kill_amount,
        "miniboss_kill_amount": miniboss_kill_amount,
        "boss_kill_amount": boss_kill_amount,
        "damage_dealt": damage_dealt,
        "damage_received": damage_received,
        "distance_traveled": distance_traveled,
        "dashes": dashes,
        "jumps": jumps
    })
    
func _init(string: String = "") -> void:
    if string.is_empty():
        return
    var data: Dictionary = JSON.parse_string(string) as Dictionary
    if data == null or data.is_empty():
        return
        
    global = data.get("global", 0)
    death_amount = data.get("death_amount", 0)
    player_kill_amount = data.get("player_kill_amount", 0)
    mob_kill_amount = data.get("mob_kill_amount", 0)
    miniboss_kill_amount = data.get("miniboss_kill_amount", 0)
    boss_kill_amount = data.get("boss_kill_amount", 0)
    damage_dealt = data.get("damage_dealt", 0)
    damage_received = data.get("damage_received", 0)
    distance_traveled = data.get("distance_traveled", 0)
    dashes = data.get("dashes", 0)
    jumps = data.get("jumps", 0)
