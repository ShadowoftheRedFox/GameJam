extends Node

const Room = preload("res://scenes/mapgen/room.tscn")

# Listen if you can't figure out what a function does based on its signature
# then I screwed up.
func create_map(width: int, height: int) -> Array:
    var map = []

    # Create nodes
    for y in range(height):
        var row = []
        for x in range(width):
            var node = Room.instantiate()
            node.room_id = Global.mapgen_get_next_unique_id()
            row.append(node)
        map.append(row)

    # Connect nodes
    # TODO: REPLACE THIS LOGIC WITH PROPER MAP GENERATION!!!
    for y in range(height):
        for x in range(width):
            var node = map[y][x]
            if y > 0:
                node.set_connection("up", map[y - 1][x])
            if y < height - 1:
                node.set_connection("down", map[y + 1][x])
            if x > 0:
                node.set_connection("left", map[y][x - 1])
            if x < width - 1:
                node.set_connection("right", map[y][x + 1])

    return map
