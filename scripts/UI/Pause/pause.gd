extends Control

var can_unpause: bool = false

@onready var control = $MarginContainer/MarginContainer/Side/Options/Controls
@onready var sound = $MarginContainer/MarginContainer/Side/Options/Sounds
@onready var resume =  $MarginContainer/MarginContainer/MarginContainer/Main/Resume
func _init() -> void:
    # since should be WHEN_PAUSE in solo and ALWAYS in multi, just set always
    process_mode = PROCESS_MODE_ALWAYS

func _ready() -> void:
    resume.grab_focus()

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed("Pause"):
        if can_unpause:
            GameController.unpause.call_deferred()
            can_unpause = false
            resume.grab_focus()
        else:
            can_unpause = true

func _on_resume_pressed() -> void:
    GameController.unpause()
    can_unpause = false
    resume.grab_focus()

func _on_settings_pressed() -> void:
    $MarginContainer/MarginContainer/MarginContainer/Main.hide()
    $MarginContainer/MarginContainer/MarginContainer/Option.show()


func _on_back_pressed() -> void:
    sound.hide()
    control.hide()
    $MarginContainer/MarginContainer/MarginContainer/Main.show()
    $MarginContainer/MarginContainer/MarginContainer/Option.hide()


func _on_sound_pressed() -> void:
    if sound.visible:
        sound.hide()
    else:
        control.hide()
        sound.show()

func _on_control_pressed() -> void:
    if control.visible:
        control.hide()
    else:
        sound.hide()
        control.show()


func _on_save_pressed() -> void:
    SaveController.save_game(GameController.hosted_save_name)


func _on_quit_pressed() -> void:
    GameController.unpause()
    resume.grab_focus()
    GameController.stop_game()
