extends Node

var mapgen_unique_id_counter: int = 0
var save_seed: int = 0

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

func generate_map(map_size: int = 0) -> Array:
    print("Starting new game...")
    print("Generating map...")
    var generator = MapGenerator.new()
    # to save the seed
    save_seed = generator.rng.seed
    
    var map: Array = generator.create_map((map_size + 1) * MAP_WIDTH, (map_size + 1) * MAP_HEIGHT, EXTRA_CONNECTION_PROBABILITY)
    if len(map) == 0:
        printerr("Something went wrong when generating map, found size 0")
        return []
    print("Generating rooms...")
    for row: Array in map:
        for room: MapRoom in row:
            var res: bool = room.generate_room()
            if res == false:
                printerr("Something went wrong with room ", room.room_id)
                return []
    # TODO save map and show it
    # TODO where to spawn player
    print("Rooms generated, starting...")
    return map

# room_types is Array[Array[String]]
func load_map(room_types: Array, map_size: int, load_seed: int) -> Array:
    var generator = MapGenerator.new()
    save_seed = load_seed
    generator.set_seed(load_seed)
    var map = generator.load_map(room_types, (map_size + 1) * MAP_WIDTH, (map_size + 1) * MAP_HEIGHT)
    return map

# get the 2D array of the room type
# map is an Array[Array[MapRoom]], result is an Array[Array[String]]
func get_map_room_types(map: Array) -> Array:
    if len(map) == 0:
        return []
    var res = []
    var i = 0
    for line in map:
        res.append([])
        for room in line:
            if room is MapRoom:
                res[i].append(room.room_type) 
            else:
                printerr("Room type is not MapRoom")
                return []
        i+=1
    return res

func free_map(map: Array):
    for line in map:
        for room in line:
            if room is MapRoom:
                room.queue_free()
