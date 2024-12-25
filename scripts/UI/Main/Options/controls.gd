extends Control

@onready var CC = $ControlsContainer

var waiting_button: Button = null
var old_key_label: String = ""
var waiting_label_name: String = ""
var is_waiting = false

func _input(event: InputEvent) -> void:
    if is_waiting == false:
        return
    
    # stop ui actions to mess while we listen to input
    if event.is_action("ui_accept"):
        accept_event()
    
    if event is InputEventKey and event.pressed:
        waiting_button.text = event.as_text()
        # save change
        SaveController.save_control(waiting_label_name, event.as_text())
        is_waiting = false

func _ready() -> void:
    SaveController.parameters_changed.connect(_on_parameters_changed)
    setup(false)
    
func setup(load_from_InputMap: bool = true) -> void:
    if load_from_InputMap == true:
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
    var french_label_name = ""
    match label_name:
        "Up":       french_label_name = "Haut"
        "Down":     french_label_name = "Bas"
        "Left":     french_label_name = "Gauche"
        "Right":    french_label_name = "Droite"
        "Jump":     french_label_name = "Saut"
        "Pause":     french_label_name = "Pause"

        _:          french_label_name = "Inconnu"
    
    label.text = french_label_name
    # text align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    # node alignement
    label.grow_horizontal = Control.GROW_DIRECTION_BOTH
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var button: Button = Button.new()
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
    
    # listen to event
    button.pressed.connect(update_input.bind(label_name, button))

func update_input(label_name: String, button: Button):
    # a new key want to be edited, cancel previous
    if is_waiting == true:
        waiting_button.text = old_key_label
    
    waiting_button = button
    waiting_label_name = label_name
    old_key_label = button.text
    button.text = "En attente de touches..."
    is_waiting = true

func clear_buttons() -> void:
    for child in CC.get_children():
        if child.name != "Reset":
            child.queue_free()

func _on_parameters_changed() -> void:
    clear_buttons()
    setup(false)

func _on_reset_pressed() -> void:
    SaveController.parameters.Controls = []
    SaveController.save_parameters()
    clear_buttons()
    setup()
