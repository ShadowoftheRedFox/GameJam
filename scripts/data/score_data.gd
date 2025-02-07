class_name ScoreData
extends Node

enum Type {
    DEATH = 1,
    PKILL = 2,
    MKILL = 3,
    MBKILL = 4,
    BKILL = 5,
    DMGD = 6,
    DMGR = 7,
    DIST = 8,
    DASH = 9,
    JMP = 10
}

var player_id: int = 0

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

@rpc("any_peer", "call_remote", "reliable")
func update_score(id: int, type: Type, value: int) -> void:
    if id != player_id:
        return
    
    # update score for everyone
    update_score.rpc(id, type, value)
    
    match type:
        Type.DEATH:
            death_amount += value
        Type.PKILL:
            player_kill_amount += value
        Type.MKILL:
            mob_kill_amount += value
        Type.MBKILL:
            miniboss_kill_amount += value
        Type.BKILL:
            boss_kill_amount += value
        Type.DMGD:
            damage_dealt += value
        Type.DMGR:
            damage_received += value
        Type.DIST:
            distance_traveled += value
        Type.DASH:
            dashes += value
        Type.JMP:
            jumps += value
        _:
            pass
    
    Game.player_infos_update.emit(null)

func get_global() -> int:
    return death_amount + \
            player_kill_amount + \
            mob_kill_amount + \
            miniboss_kill_amount + \
            boss_kill_amount + \
            damage_dealt + \
            damage_received + \
            distance_traveled + \
            dashes + \
            jumps

func _to_string() -> String:
    return JSON.stringify({
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
