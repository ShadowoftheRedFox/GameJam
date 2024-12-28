class_name LoadingScreen
extends CanvasLayer

signal transition_completed

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var message: Label = $MarginContainer/Text

func start_transition(anim_name: String) -> void:
    # check if we got our node
    if !animation_player:
        animation_player = get_node("AnimationPlayer") as AnimationPlayer
    
    # check if animation exist
    if !animation_player.has_animation(anim_name):
        push_warning("'%s' start animation does not exist!" % anim_name)
        anim_name = "fade_to_black"
    
    animation_player.play(anim_name)

func finish_transition(anim_name: String) -> void:
    # Checking if the animation exist within the loading animation player
    if !animation_player.has_animation(anim_name):
        push_warning("'%s' finish animation does not exist!" % anim_name)
        anim_name = "fade_from_black"
        
    animation_player.play(anim_name)
    
    await animation_player.animation_finished
    queue_free()

# send the signal for the transition completion (the screen is now fully hidden behind the loading scene)
func complete_transition() -> void:
    transition_completed.emit()
