class_name StateMachine 
extends Node

@export var initial_state: State = null
var state: State = null

func _ready() -> void:
    state = get_initial_state()
    
    for state_node: State in find_children("*", "State"):
        state_node.finished.connect(_transition_to_next_state)
        # assign entity to each state
        state_node.entity = owner

    await owner.ready
    state.enter("")


func get_initial_state() -> State:
    return initial_state if initial_state != null else get_child(0)


func _unhandled_input(event: InputEvent) -> void:
    state.handle_input(event)


func _process(delta: float) -> void:
    state.update(delta)


func _physics_process(delta: float) -> void:
    state.physics_update(delta)


func _transition_to_next_state(target_state_path: String, data: Dictionary = {}) -> void:
    if !has_node(target_state_path):
        printerr(owner.name + ": Trying to transition to state " + target_state_path + " but it does not exist.")
        return

    var previous_state_path := state.name
    state.exit()
    state = get_node(target_state_path)
    state.enter(previous_state_path, data)
