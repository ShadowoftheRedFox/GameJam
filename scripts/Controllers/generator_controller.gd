extends Node

var mapgen_unique_id_counter: int = 0
var seed = 0

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

@export var MAP_WIDTH: int = 10
@export var MAP_HEIGHT: int = 10
@export var EXTRA_CONNECTION_PROBABILITY: float = 0.1

@export var ROOM_WIDTH: int = 10
@export var ROOM_HEIGHT: int = 10

func generate_map(map_size: int = 0) -> void:
    print("Starting new game...")
    print("Generating map...")
    var generator = MapGenerator.new()
    # to save the seed
    seed = generator.rng.seed
    
    var map: Array = generator.create_map((map_size + 1) * MAP_WIDTH, (map_size + 1) * MAP_HEIGHT, EXTRA_CONNECTION_PROBABILITY)
    if len(map) == 0:
        printerr("Something went wrong when generating map, found size 0")
        return
    print("Generating rooms...")
    for row: Array in map:
        for room: MapRoom in row:
            var res: bool = room.generate_room()
            if res == false:
                printerr("Something went wrong with room ", room.room_id)
                return
    # TODO save map and show it
    # TODO where to spawn player
    print("Rooms generated, starting...")
    
    
