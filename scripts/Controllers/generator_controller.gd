class_name GeneratorControllerScript
extends Node

var mapgen_unique_id_counter: int = 0
var save_seed: int = 0

func mapgen_get_next_unique_id() -> int:
    mapgen_unique_id_counter += 1
    return mapgen_unique_id_counter

@export var MAP_WIDTH: int = 10
@export var MAP_HEIGHT: int = 10
@export var EXTRA_CONNECTION_PROBABILITY: float = 0.1

@export var ROOM_WIDTH: int = 10
@export var ROOM_HEIGHT: int = 10

func generate_map(map_size: int = 0) -> MapData:
    var data = MapData.new()
    print("Starting new game...")
    print("Generating map...")
    var generator = MapGenerator.new()
    # to save the seed
    save_seed = generator.rng.seed
    
    var map: Array = generator.create_map((map_size + 1) * MAP_WIDTH, (map_size + 1) * MAP_HEIGHT, EXTRA_CONNECTION_PROBABILITY)
    if len(map) == 0:
        printerr("Something went wrong when generating map, found size 0")
        return data
    
    print("Generating rooms...")
    var max_room_size: Vector2 = Vector2()
    for row: Array in map:
        for room: MapRoom in row:
            var res: bool = room.generate_room()
            if res == false:
                printerr("Something went wrong with room ", room.room_id)
                return data
            # get the size of the map
            var tile_map = room.Map
            var tile_rect = tile_map.get_used_rect()
            var cell_size = tile_map.tile_set.tile_size
            var limit_left = tile_rect.position.x * cell_size.x
            var limit_top = tile_rect.position.y * cell_size.y
            var limit_right = tile_rect.end.x * cell_size.x
            var limit_bottom = tile_rect.end.y * cell_size.y
            if abs(limit_right - limit_left) > max_room_size.x:
                max_room_size.x = abs(limit_right - limit_left)
            if abs(limit_bottom - limit_top) > max_room_size.y:
                max_room_size.y = abs(limit_bottom - limit_top)

    print("Generating content...")
    var buffs_in_rooms: Array = []
    for y: int in map.size():
        buffs_in_rooms.append([])
        for x: int in map[y].size():
            var room: MapRoom = map[y][x]
            
            # put buff in all spawn for now
            var buff_type: int = randi_range(Buff.BuffPreset.CUSTOM + 1, Buff.BuffPreset.MAX - 1)
            var buff: Buff = Game.BuffScene.instantiate()
            @warning_ignore("int_as_enum_without_cast")
            buff.buff_preset = buff_type
            
            room.BuffSpawn.add_child(buff)
            buffs_in_rooms[y].append(buff_type)
                          
            var ennemy = Game.OrcScene.instantiate() if randi_range(0, 1) else Game.SlimeScene.instantiate()
            room.BuffSpawn.add_child(ennemy)
            
            var tile_map = room.Map
            var tile_rect = tile_map.get_used_rect()
            var cell_size = tile_map.tile_set.tile_size
            if abs(tile_rect.end.x * cell_size.x) > data.room_size.x:
                data.room_size.x = abs(tile_rect.end.x * cell_size.x)
            if abs(tile_rect.end.y * cell_size.y) > data.room_size.y:
                data.room_size.y = abs(tile_rect.end.y * cell_size.y)
    
    data.room_size = max_room_size
    data.loaded_rooms = map
    data.room_types = get_map_room_types(data.loaded_rooms)
    data.buff_types = buffs_in_rooms
    data.load_valid = true
    data.save_valid = true
    return data

# room_types is Array[Array[String]]
func load_map(data: MapData, map_size: int, load_seed: int) -> MapData:
    var generator = MapGenerator.new()
    save_seed = load_seed
    generator.set_seed(load_seed)
    return generator.load_map(data, (map_size + 1) * MAP_WIDTH, (map_size + 1) * MAP_HEIGHT)

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
        i += 1
    return res

func free_map(map: Array):
    for line in map:
        for room in line:
            if room is MapRoom:
                room.queue_free()
