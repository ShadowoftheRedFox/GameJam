class_name UtilsScript
extends Node

func remove_signal_listener(sig: Signal) -> void:
    for dict in sig.get_connections():
        sig.disconnect(dict.callable)

# key: String, value: int
var num_scenes_in_dir = {}
func get_num_files_in_dir(path: String, ends_with = ".tscn") -> int:
    if num_scenes_in_dir.has(path):
        return num_scenes_in_dir.get(path) as int
    
    var dir = DirAccess.open(path)
    var count = 0
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(ends_with):
                count += 1
            file_name = dir.get_next()
        # do not add path if dir not found
        num_scenes_in_dir.get_or_add(path, count)
    
    return count

func random_str(length: int, chars: String = "abcdefghijklmnopqrstuvwxyz0123456789") -> String:
    if length <= 0:
        return ""
    
    var word: String = ""
    var n_char = len(chars)
    for i in range(length):
        word += chars[randi() % n_char]
    return word
