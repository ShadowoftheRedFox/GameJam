class_name ThreadControllerScript
extends Node

var unique_id: int = 0

func load_scene(path: String, type_hint: String) -> Variant:
    var loaded_signal = "loaded_"+str(unique_id)
    self.add_user_signal(loaded_signal, [{
        "name": "scene", "type": PROPERTY_HINT_RESOURCE_TYPE
    }])
    unique_id+=1
    
    if not ResourceLoader.exists(path):
        printerr("Invalid path provided: ", path)
        return null
    # load our scene
    var loader = ResourceLoader.load_threaded_request(path, type_hint)
    if loader == null:
        printerr("Something went wrong when loading ", path)
        return null
    
    # launch a timer if we want loading bar
    var transition_timer := Timer.new()
    transition_timer.wait_time = 0.1
    # check status (so update loading bar) every 0.1s
    transition_timer.timeout.connect(_check_load_status.bind(path, transition_timer, loaded_signal))
    get_tree().root.add_child(transition_timer)
    transition_timer.start()
    
    return loaded_signal
    
func load_scene_array(path: Array[String], type_hint: String) -> Array[Signal]:
    var update_signal = Signal()
    var loaded_signal = Signal()
    var all_loaded_signal = Signal()
    
    return [update_signal, loaded_signal, all_loaded_signal]
    
func _check_load_status(path:String, transition_timer: Timer, loaded_signal: String)->void:
    # get our loading status
    var load_status = ResourceLoader.load_threaded_get_status(path)

    match load_status:
        ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            printerr("Invalid resource: ", path)
            if transition_timer != null:
                transition_timer.stop()
                transition_timer.queue_free()
            return
        ResourceLoader.THREAD_LOAD_FAILED:
            printerr("Failed to load: ", path)
            if transition_timer != null:
                transition_timer.stop()
                transition_timer.queue_free()
            return
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            #print("Loading: ", path)
            return
        ResourceLoader.THREAD_LOAD_LOADED:
            # loading is finished, destroy the timer
            transition_timer.stop()
            transition_timer.queue_free()
            # get our loaded scene
            var new_scene: PackedScene = ResourceLoader.load_threaded_get(path)
            # emit our scene
            self.emit_signal(loaded_signal, new_scene)
            print("stopping ", path)
