class_name PlayerDataManager

var list: Array[PlayerData] = []

func reset() -> void:
    #for p in list:
        #p.unreference()
    list = []

## Returns the amount of non-spectator
func get_player_count() -> int:
    var res = 0
    for p in list:
        res += int(!p.is_spectator)
    return res

func get_players_ids() -> Array[int]:
    var res: Array[int] = []
    for p in list:
        res.append(p.id)
    return res

func has_player(id: int) -> bool:
    for p in list:
        if p.id == id:
            return true
    return false
    
func has_all_players(ids: Array[int]) -> bool:
    for id in ids:
        if !has_player(id):
            return false
    return true

func get_player(id: int) -> PlayerData:
    for p in list:
        if p.id == id:
            return p
    return null
    
func erase_player(id: int) -> void:
    var temp: Array[PlayerData] = []
    for i in list.size():
        if list[i].id != id:
            temp.append(list[i])
        else:
            list[i].unreference()
    list = temp.duplicate()
    
func as_dictionary() -> Dictionary:
    var res = {}
    for p in list:
        res.get_or_add(p.id, p)
    return res
