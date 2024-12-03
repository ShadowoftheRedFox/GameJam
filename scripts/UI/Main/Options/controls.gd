extends Control

@onready var CC = $ControlsContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    InputMap.load_from_project_settings()
    # all godot default actions start with ui, so ignore those
    var input_map = InputMap.get_actions().filter(func(s: String): return !s.begins_with("ui_"))
    
    # for each of these, add a button and get the key
    for input_name in input_map:
        # TODO only take the first one (yet)
        var event_key: InputEvent = InputMap.action_get_events(input_name)[0]
        create_input_button(input_name, event_key.as_text())
    
func create_input_button(label_name: String, key_name: String) -> void:
    var node := MarginContainer.new()
    node.name = label_name
    node.add_theme_constant_override("margin_right", 100)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 20)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    node.grow_horizontal = Control.GROW_DIRECTION_BOTH
    
    var label = Label.new()
    # node name
    label.text = label_name
    # text align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    # node alignement
    label.grow_horizontal = Control.GROW_DIRECTION_BOTH
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var button = Button.new()
    # node name
    button.text = key_name
    # text align
    button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    # node alignement
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    hbox.add_child(label)
    hbox.add_child(button)
    node.add_child(hbox)
    CC.add_child(node)
    
    # TODO listen to event
    # TODO change label_name from english to french

func update_input():
    pass
