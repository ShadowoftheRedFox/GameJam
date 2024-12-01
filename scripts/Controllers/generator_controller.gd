extends Node

var mapgen_unique_id_counter: int = 0
func mapgen_get_next_unique_id() -> int:
    mapgen_unique_id_counter += 1
    return mapgen_unique_id_counter

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
                count+=1
            file_name = dir.get_next()
        # do not add path if dir not found
        num_scenes_in_dir.get_or_add(path, count)
    
    return count 
