extends Control

const LOW_PERF_NAME = "lowperf"

@onready var low_perf_button: CheckButton = $Main/HBoxContainer/LowPerf

func _ready() -> void:
    var lowperf = Save.get_parameter(LOW_PERF_NAME);
    if lowperf == true:
        low_perf_button.button_pressed = true

func _on_text_edit_text_changed(new_text: String) -> void:
    if new_text.length() > 0:
        Save.parameters.Multiplayer.name = new_text
        Save.save_parameters()


func _on_color_picker_color_changed(color: Color) -> void:
    Save.parameters.Multiplayer.color = color.to_html(false)
    Save.save_parameters()


func _on_low_perf_toggled(toggled_on: bool) -> void:
    Game.LOW_PERF = toggled_on
    Save.save_parameter(LOW_PERF_NAME, toggled_on)
