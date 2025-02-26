class_name PlayerData
extends Node

var id: int = 0
var color: String = "ff0000"
var score: ScoreData = ScoreData.new()
var buff: Array[BuffData] = []
var is_spectator: bool = false

func _to_string() -> String:
    return JSON.stringify({
        "id": id,
        "name": name,
        "color": color,
        "score": score,
        "buff": buff,
        "is_spectator": is_spectator,
    })

func _init(string: String = "") -> void:
    if string.is_empty():
        return
    var data: Dictionary = JSON.parse_string(string) as Dictionary
    if data == null or data.is_empty():
        return

    id = data.get("id", 0)
    name = data.get("name", "(Aucun)")
    color = data.get("color", "ff0000")
    score = ScoreData.new(data.get("score", ""))
    score.player_id = id
    score.name = name + "Score"
    add_child(score)
    
    var raw_buff = data.get("buff", [])
    for buff_data in raw_buff:
        buff.append(BuffData.new(buff_data))
    
    is_spectator = data.get("is_spectator", false)

func has_buff(buff_type: int) -> bool:
    for b in buff:
        if b.buff_type == buff_type:
            return true
    return false
    
func get_buff(buff_type: int) -> BuffData:
    for b in buff:
        if b.buff_type == buff_type:
            return b
    return null

func add_buff(buff_type: int) -> void:
    var buff_data = BuffData.new()
    buff_data.buff_type = buff_type
    
    if has_buff(buff_data.buff_type):
        get_buff(buff_data.buff_type).buff_amount += 1
    else:
        buff_data.first_got = Time.get_unix_time_from_system()
        buff.append(buff_data)

func get_color() -> Color:
    return Color(color)
