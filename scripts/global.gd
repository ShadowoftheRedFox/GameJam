extends Node

# for the future, to pre load scenes:
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html#doc-background-loading

signal scene_changed

# current loaded scene
var current_scene = null
# the loading scene
var loading_scene = preload("res://scenes/UI/Loading.tscn")
# the loading script
var loading: LoadingScreen = null
var transition_start:String
var transition_end:String
var transition_timer: Timer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var root = get_tree().root
	# load the first scece found
	current_scene = root.get_child(-1)

func goto_scene(path:String = "res://scenes/UI/MainMenu.tscn", need_transition:bool = false, start_transition_name:String = "fade_to_black", end_transition_name:String = "fade_from_black") ->void:
	# This function will usually be called from a signal callback,
	# or some other function in the current scene.
	# Deleting the current scene at this point is
	# a bad idea, because it may still be executing code.
	# This will result in a crash or unexpected behavior.

	# The solution is to defer the load to a later time, when
	# we can be sure that no code from the current scene is running:
	if need_transition == true:
		transition_start = start_transition_name
		transition_end = end_transition_name
		_deferred_change_scene.call_deferred(path)
	else:
		_deferred_goto_scene.call_deferred(path)

func _deferred_goto_scene(path:String = "res://scenes/UI/MainMenu.tscn"):
	# It is now safe to remove the current scene.
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instantiate()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene

func _deferred_change_scene(path:String = "res://scenes/UI/MainMenu.tscn"):
	# load and display our transition scene
	loading = loading_scene.instantiate() as LoadingScreen
	get_tree().root.add_child(loading)
	# launch the transition effect
	loading.start_transition(transition_start)
	# Load the new scene.
	_load_new_scene(path)

func _load_new_scene(path:String)->void:
	# wait for the transition effect to finish
	if loading != null:
		await loading.transition_completed
	if not ResourceLoader.exists(path):
		printerr("Invalid path provided: ", path)
		return
	# load our scene
	var loader = ResourceLoader.load_threaded_request(path)
	if loader == null:
		printerr("Something went wrong when loading ", path)
		return

	# launch a timer if we want loading bar
	transition_timer = Timer.new()
	transition_timer.wait_time = 0.1
	# check status (so update loading bar) every 0.1s
	transition_timer.timeout.connect(_check_load_status.bind(path))
	get_tree().root.add_child(transition_timer)
	transition_timer.start()

func _check_load_status(path:String = "res://scenes/UI/MainMenu.tscn")->void:
	# get our loading status
	var load_status = ResourceLoader.load_threaded_get_status(path)

	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			printerr("Invalid resource: ", path)
			pass
		ResourceLoader.THREAD_LOAD_FAILED:
			printerr("Failed to load: ", path)
			pass
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print("Loading: ", path)
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
			# loading is finished, destroy the timer
			transition_timer.stop()
			transition_timer.queue_free()
			# get our loaded scene
			var new_scene = ResourceLoader.load_threaded_get(path).instantiate()
			# It is now safe to remove the current scene.
			get_tree().current_scene.call_deferred("free")
			# add scene to root
			get_tree().root.call_deferred("add_child",new_scene)
			# equivalent to current_scene = new_scene
			get_tree().set_deferred("current_scene",new_scene)
			# end the transition
			loading.finish_transition(transition_end)
			# emit our scene change end
			scene_changed.emit()

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
