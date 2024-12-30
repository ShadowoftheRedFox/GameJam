class_name ThreadControllerScript
extends Node

const THREAD_THRESHOLD = 16
var active_thread = 0:
    set(value):
        active_thread = value
        if value >= THREAD_THRESHOLD:
            push_warning("Threshold reached, ", THREAD_THRESHOLD, " threads active simultaneously")

signal thread_finished(result: Variant)

#signal multiple_thread_finished(id: int, result: Variant)
#signal multiple_thread_progress
#signal multiple_thread_complete

# the loading scene
var loading_scene = preload("res://scenes/UI/Loading.tscn")
# the loading script
var loading: LoadingScreen = null
var transition_start: String = "fade_to_black"
var transition_end: String = "fade_from_black"
var transition_timer: Timer = null
# synchronizing multiple threads
var mutex: Mutex = Mutex.new()
#var semaphore: Semaphore = Semaphore.new()
# because it is slow to create thread on windows
# TODO check if it is, function will behave diferently
var is_windows: bool = OS.get_name() == "Windows"

func thread_transition(
    workload: Callable, 
    callback: Signal = thread_finished,
    show_loading: bool = false,
    message: String = "Chargement en cours...", 
    start_transition: String = "fade_to_black",
    end_transition: String = "fade_from_black"
) -> bool:
    
    if workload == null:
        return false
    
    var thread := Thread.new()
    var err := thread.start(workload)
    if err != OK:
        push_warning("Error while creating thread: ", err)
        return false
    
    mutex.lock()
    active_thread += 1
    mutex.unlock()
    
    if show_loading:
        transition_start = start_transition
        transition_end = end_transition
        # load and display our transition scene
        if loading != null:
            await loading.transition_completed
        loading = loading_scene.instantiate() as LoadingScreen
        get_tree().root.add_child(loading)
        loading.message.text = message
        # launch the transition effect
        loading.start_transition(transition_start)
    
    # launch a timer if we want loading bar
    transition_timer = Timer.new()
    transition_timer.wait_time = 0.1
    # check status (so update loading bar) every 0.1s
    transition_timer.timeout.connect(_check_thread_status.bind(thread, callback, show_loading))
    get_tree().root.add_child(transition_timer)
    transition_timer.start()
    return true

func _check_thread_status(thread: Thread, callback: Signal, show_loading: bool) -> void:
    if thread.is_alive() == false:
        # callback if there is one, else finish it anyway
        if !callback.is_null():
            callback.emit(thread.wait_to_finish())
        else:
            thread_finished.emit(thread.wait_to_finish())   
        
        mutex.lock()
        active_thread -= 1
        mutex.unlock()
        
        transition_timer.stop()
        transition_timer.queue_free()
        if show_loading:
            loading.finish_transition(transition_end)
