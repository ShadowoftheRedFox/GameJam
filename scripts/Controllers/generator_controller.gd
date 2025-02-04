class_name GeneratorControllerScript
extends Node

const Room: PackedScene = preload("res://scenes/levels/BaseRoom.tscn")

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
    
    data.loaded_rooms = generator.create_map((map_size + 1) * MAP_WIDTH, (map_size + 1) * MAP_HEIGHT, EXTRA_CONNECTION_PROBABILITY)
    if len(data.loaded_rooms) == 0:
        printerr("Something went wrong when generating map, found size 0")
        return data
    
    print("Generating rooms...")
    var max_room_size: Vector2 = Vector2()
    for row: Array in data.loaded_rooms:
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
    data.buff_types = []
    for y: int in data.loaded_rooms.size():
        data.buff_types.append([])
        for x: int in data.loaded_rooms[y].size():
            var room: MapRoom = data.loaded_rooms[y][x]
            
            # put buff in all spawn for now
            data.buff_types[y].append(randi_range(Buff.BuffPreset.CUSTOM + 1, Buff.BuffPreset.MAX - 1))
            
            fill_room(room, data, x, y)
    
    data.room_size = max_room_size
    data.room_types = get_map_room_types(data.loaded_rooms)
    data.load_valid = true
    data.save_valid = true
    return data

# room_types is Array[Array[String]]
func load_map(data: MapData, map_size: int) -> MapData:
    var width = (map_size + 1) * MAP_WIDTH
    var height = (map_size + 1) * MAP_HEIGHT
    data.loaded_rooms = []
    
    # Create nodes
    for y in range(height):
        var row = []
        for x in range(width):
            var node: MapRoom = Room.instantiate()
            node.room_id = Game.GeneratorController.mapgen_get_next_unique_id()
            node.room_position = Vector2(x, y)
            row.append(node)
        data.loaded_rooms.append(row)
        
    for y in range(height):
        for x in range(width):
            var room: MapRoom = data.loaded_rooms[y][x]
            
            var room_right: Node = null
            var room_up: Node = null
            var room_down: Node = null
            var room_left: Node = null
            
            if x > 0:
                room_left = data.loaded_rooms[y][x - 1]
            if x < width - 1:
                room_right = data.loaded_rooms[y][x + 1]
            if y > 0:
                room_up = data.loaded_rooms[y - 1][x]
            if y < height - 1:
                room_down = data.loaded_rooms[y + 1][x]
                
            room.set_room(data.room_types[y][x], room_left, room_right, room_up, room_down)
            room.check_room_valid()
            
            fill_room(room, data, x, y)
            
    # add one boss
    var pos := Vector2i(int(width/2.0), int(height/2.0))
    (data.loaded_rooms[pos.y][pos.x] as MapRoom).PlayerSpawn.add_child(Game.BossScene.instantiate())
    print("boss in ", pos)
    
    data.load_valid = true
    return data

func fill_room(room: MapRoom, data: MapData, x: int, y: int) -> void:
    if data.buff_types[y][x] != Buff.BuffPreset.NONE:
        var buff: Buff = Game.BuffScene.instantiate()
        @warning_ignore("int_as_enum_without_cast")
        buff.buff_preset = data.buff_types[y][x]
        room.BuffSpawn.add_child(buff)
        buff.apply_to_children.call_deferred()
    
    var ennemy = Game.OrcScene.instantiate() if Game.rng.randi_range(0, 1) else Game.SlimeScene.instantiate()
    room.BuffSpawn.add_child(ennemy)
    
    var tile_map = room.Map
    var tile_rect = tile_map.get_used_rect()
    var cell_size = tile_map.tile_set.tile_size
    if abs(tile_rect.end.x * cell_size.x) > data.room_size.x:
        data.room_size.x = abs(tile_rect.end.x * cell_size.x)
    if abs(tile_rect.end.y * cell_size.y) > data.room_size.y:
        data.room_size.y = abs(tile_rect.end.y * cell_size.y)

## get the 2D array of the room type
## map is an Array[Array[MapRoom]], result is an Array[Array[String]]
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
