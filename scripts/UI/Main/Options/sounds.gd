extends Control

func _ready() -> void:
    Save.parameters_changed.connect(_on_parameters_changed)

func _on_parameters_changed() -> void:
    $Sound/Music/HBoxContainer/HSlider.value = float(Save.parameters.Sounds.music)
    $Sound/Sfx/HBoxContainer/HSlider.value = float(Save.parameters.Sounds.sfx)
    $Sound/Entities/HBoxContainer/HSlider.value = float(Save.parameters.Sounds.entities)
    

func _on_music_value_changed(value: float) -> void:
    Save.parameters.Sounds.music = int(value)


func _on_sfx_value_changed(value: float) -> void:
    Save.parameters.Sounds.sfx = int(value)


func _on_entities_value_changed(value: float) -> void:
    Save.parameters.Sounds.entities = int(value)
