class_name MapData

## Array[Array[String]]
var room_types: Array = []
#var buff_types: Array = []

## Array[Array[MapRoom]]
var loaded_rooms: Array = []

var room_size: Vector2 = Vector2(0, 0)

var save_valid: bool = false
var load_valid: bool = false

func parse(data: Dictionary) -> bool:
    save_valid = false
    
    if data.is_empty():
        printerr("given dictionary is empty")
        return false
    
    if !data.has("room_types"):
        printerr("data has no room_types")
        return false
    room_types = data.get("room_types")
    
    #if !data.has("buff_types"):
        #printerr("data has no buff_types")
        #return false
    #buff_types = data.get("buff_types")
    
    if !data.has("room_size") or !data.get("room_size").has("x") or !data.get("room_size").has("y"):
        printerr("data has no room_size")
        return false
    room_size = Vector2(data.get("room_size").get("x"), data.get("room_size").get("y"))
    
    save_valid = true
    return true

func _to_save() -> Dictionary:
    if !save_valid:
        push_warning("map_data is not in a valid save state")
    
    return {
        "room_types": room_types,
        #"buff_types": buff_types,
        "room_size": {
            "x": room_size.x,
            "y": room_size.y
        }
    }

func _to_string() -> String:  
    return JSON.stringify(_to_save())
