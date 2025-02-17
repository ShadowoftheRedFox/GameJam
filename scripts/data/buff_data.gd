class_name BuffData

## Time when we got the first buff in seconds (float for sub-second precision
var first_got: float = 0
var buff_type: int = Buff.CUSTOM
var buff_amount: int = 1

func _to_string() -> String:
    return JSON.stringify({
        "first_got": first_got,
        "buff_type": buff_type,
        "buff_amount": buff_amount
    })
    
func _init(string: String = "") -> void:
    if string.is_empty():
        return
    var data: Dictionary = JSON.parse_string(string) as Dictionary
    if data == null or data.is_empty():
        return
    first_got = data.get("first_got", 0)
    buff_type = data.get("buff_type", Buff.CUSTOM)
    buff_amount = data.get("buff_amount", 0)

func get_buff_name() -> String:
    if buff_type == Buff.NONE:
        return 'None';
    if buff_type == Buff.MAX:
        return 'Max'; 
    return Buff.buff_title[buff_type]
    
func get_buff_title() -> String:
    return Buff.buff_title[buff_type]
    
func get_buff_description() -> String:
    return Buff.buff_description[buff_type]
