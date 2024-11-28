extends Node

const Room = preload("res://scenes/mapgen/room.tscn")
# TODO: USE A REAL ALGORITHM
var rng = RandomNumberGenerator.new()

# Listen if you can't figure out what a function does based on its signature
# then I screwed up.
func create_map(width: int, height: int, probability: float) -> Array:
	var map = []

	# Create nodes
	for y in range(height):
		var row = []
		for x in range(width):
			var node = Room.instantiate()
			node.room_id = Global.mapgen_get_next_unique_id()
			row.append(node)
		map.append(row)

	### REALLY QUICK AND DIRTY DFS IMPLEMENTATION
	# Apparently my cool tree-based approach was a PITA to implement. Close enough.
	var stack = []
	# Mark all nodes as unvisited.
	# I find the idea of creating 2D arrays like this REALLY funny.
	# O(Scary)
	var visited = []
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(false)
		visited.append(row)

	# Lots of algorithms suggested starting in a random spot.
	# I cba
	stack.append(Vector2(0, 0))
	visited[0][0] = true
	while stack.size() > 0:
		var current = stack[stack.size() - 1] # Maybe JS' negative indices aren't so evil.
		var x = current.x
		var y = current.y

		# Add every unvisited neighbor to our little list
		var neighbors = []
		if y > 0 and not visited[y - 1][x]:
			neighbors.append(Vector2(x, y - 1))
		if y < height - 1 and not visited[y + 1][x]:
			neighbors.append(Vector2(x, y + 1))
		if x > 0 and not visited[y][x - 1]:
			neighbors.append(Vector2(x - 1, y))
		if x < width - 1 and not visited[y][x + 1]:
			neighbors.append(Vector2(x + 1, y))

		# If we don't have any unvisited neighbors, try the previous current
		if neighbors.size() == 0:
			stack.pop_back()
		else:
			# Otherwise, visit them! Duh! Idiot.
			# Choose a random neighbor
			var next = neighbors[rng.randi_range(0, neighbors.size() - 1)]

			# Connect the current node and its neighbor
			# TODO: Maybe allow one-ways?
			if next.y < y:
				map[y][x].set_connection("up", map[next.y][next.x])
				map[next.y][next.x].set_connection("down", map[y][x])
			elif next.y > y:
				map[y][x].set_connection("down", map[next.y][next.x])
				map[next.y][next.x].set_connection("up", map[y][x])
			elif next.x < x:
				map[y][x].set_connection("left", map[next.y][next.x])
				map[next.y][next.x].set_connection("right", map[y][x])
			elif next.x > x:
				map[y][x].set_connection("right", map[next.y][next.x])
				map[next.y][next.x].set_connection("left", map[y][x])

			# So anyways, I started stacking.
			visited[next.y][next.x] = true
			stack.append(next)

	# Add random connections because I FUCKING LOVE LOOPS IM LOOPING IM GONNA
	# LOOP ALWAYS LOOP I LOVE LOOPING HOLY FUCK
	for y in range(height):
		for x in range(width):
			var node = map[y][x]
			if rng.randf() < probability:
				if y > 0 and not node.get_connection("up"):
					node.set_connection("up", map[y - 1][x])
					map[y - 1][x].set_connection("down", node)
			if rng.randf() < probability:
				if y < height - 1 and not node.get_connection("down"):
					node.set_connection("down", map[y + 1][x])
					map[y + 1][x].set_connection("up", node)
			if rng.randf() < probability:
				if x > 0 and not node.get_connection("left"):
					node.set_connection("left", map[y][x - 1])
					map[y][x - 1].set_connection("right", node)
			if rng.randf() < probability:
				if x < width - 1 and not node.get_connection("right"):
					node.set_connection("right", map[y][x + 1])
					map[y][x + 1].set_connection("left", node)


	return map
