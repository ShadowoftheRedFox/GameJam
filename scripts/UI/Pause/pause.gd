extends Control

var can_unpause: bool = false

@onready var control = $MarginContainer/MarginContainer/Side/Options/Controls
@onready var sound = $MarginContainer/MarginContainer/Side/Options/Sounds

func _init() -> void:
    process_mode = PROCESS_MODE_WHEN_PAUSED

func _ready() -> void:
    $MarginContainer/MarginContainer/MarginContainer/Main/Resume.grab_focus()

func _input(event: InputEvent) -> void:
    if event.is_action_released("Pause"):
        if can_unpause:
            GameController.unpause()
            can_unpause = false
        else:
            can_unpause = true

func _on_resume_pressed() -> void:
    GameController.unpause()
    can_unpause = false


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
    SaveController.save_game(GameController.save_name_hosted)


func _on_quit_pressed() -> void:
    GameController.unpause()
    GameController.stop_game()
