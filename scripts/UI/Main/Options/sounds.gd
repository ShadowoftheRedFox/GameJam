extends Control

func _ready() -> void:
    SaveController.parameters_changed.connect(_on_parameters_changed, ConnectFlags.CONNECT_PERSIST)

func _on_parameters_changed() -> void:
    $Sound/Music/HBoxContainer/HSlider.value = float(SaveController.parameters.Sounds.music)
    $Sound/Sfx/HBoxContainer/HSlider.value = float(SaveController.parameters.Sounds.sfx)
    $Sound/Entities/HBoxContainer/HSlider.value = float(SaveController.parameters.Sounds.entities)
    

func _on_music_value_changed(value: float) -> void:
    SaveController.parameters.Sounds.music = int(value)


func _on_sfx_value_changed(value: float) -> void:
    SaveController.parameters.Sounds.sfx = int(value)


func _on_entities_value_changed(value: float) -> void:
    SaveController.parameters.Sounds.entities = int(value)
