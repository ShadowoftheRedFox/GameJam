extends Control

@onready var Main = $MarginContainer/ControlsContainer/Main

var waiting_button: Button = null
var old_key_label: String = ""
var waiting_label_name: String = ""
var is_waiting_key = false
var is_waiting_controller = false
var input_waiting_change: InputEvent = null

func _input(event: InputEvent) -> void:
    if !is_waiting_key and !is_waiting_controller:
        return

    # stop ui actions to mess while we listen to input
    if event.is_action("ui_accept"):
        accept_event()

    if event is InputEventKey and event.pressed and is_waiting_key:
        waiting_button.text = event.as_text()
        # save change
        SaveController.save_control(waiting_label_name, str(event), false)
        is_waiting_key = false
    
    if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and is_waiting_controller:
        # force value at -+1.0
        if event is InputEventJoypadMotion:
            event.axis_value = ceil(event.axis_value)
        
        waiting_button.text = event.as_text()
        # save change
        SaveController.save_control(waiting_label_name, str(event), true)
        is_waiting_controller = false

func _ready() -> void:
    SaveController.parameters_changed.connect(_on_parameters_changed)
    setup()

func setup() -> void:
    # all godot default actions start with ui, so ignore those
    var input_map = InputMap.get_actions().filter(func(s: String): return !s.begins_with("ui_"))

    # for each of these, add a button and get the key
    for input_name in input_map:
        var event_actions = InputMap.action_get_events(input_name)
        var event_key: InputEvent = event_actions[0] if event_actions.size() >= 1 else null
        var event_controller: InputEvent = event_actions[1] if event_actions.size() >= 2 else null
        create_input_button(input_name, event_key, event_controller)

func create_input_button(label_name: String, key: InputEvent, controller: InputEvent) -> void:
    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 20)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH

    var label = Label.new()
    # node name
    var french_label_name = ""
    match label_name:
        "Up":       french_label_name = "Haut"
        "Down":     french_label_name = "Bas"
        "Left":     french_label_name = "Gauche"
        "Right":    french_label_name = "Droite"
        "Jump":     french_label_name = "Saut"
        "Pause":    french_label_name = "Pause"
        "Dash":     french_label_name = "Dash"
        _:          french_label_name = label_name

    label.text = french_label_name
    # text align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    # node alignement
    label.grow_horizontal = Control.GROW_DIRECTION_BOTH
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    # stretch ratio
    label.size_flags_stretch_ratio = 0.3
    
    var button_key: Button = Button.new()
    var button_controller: Button = Button.new()
    # node name
    button_key.text = key.as_text() if key != null else "(Aucun)"
    button_controller.text = controller_button_name(controller)
    # text align
    button_key.alignment = HORIZONTAL_ALIGNMENT_CENTER
    button_controller.alignment = HORIZONTAL_ALIGNMENT_CENTER
    # node alignement
    button_key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_controller.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    hbox.add_child(label)
    hbox.add_child(button_key)
    hbox.add_child(button_controller)
    Main.add_child(hbox)

    # listen to event
    button_key.pressed.connect(update_input.bind(label_name, button_key, key, false))
    button_controller.pressed.connect(update_input.bind(label_name, button_controller, controller, true))
    # TODO to finish: save the controller with save manager, and load, then check if input if listened with player

func controller_button_name(event: InputEvent) -> String:
    if event == null:
        return "(Aucun)"
    var base_name = event.as_text()
    
    if event is InputEventJoypadButton:
        # button name looks like this: Joypad Button 1 (Right Action, Sony Circle, Xbox B, Nintendo A)
        # we will keep just "Button X"
        var format := base_name.erase(0, len("Joypad "))
        # find first occurence of ( and erase everything after
        var start_parenthesis = format.find("(")
        return format.erase(start_parenthesis-1, len(format))
    
    if event is InputEventJoypadMotion:
        # button name looks like this: Joypad Motion on Axis 1 (Left Stick Y-Axis, Joystick 0 Y-Axis) with Value -1.00
        # we want "Left/Right joystick UP/DOWN/LEFT/RIGHT
        match event.axis:
            # Game controller left joystick x-axis.
            JOY_AXIS_LEFT_X:
                return "Left joystick " + ("right" if event.axis_value > 0 else "left")
            # Game controller left joystick y-axis.
            JOY_AXIS_LEFT_Y:
                return "Left joystick " + ("down" if event.axis_value > 0 else "up")
            # Game controller right joystick x-axis.
            JOY_AXIS_RIGHT_X:
                return "Right joystick " + ("right" if event.axis_value > 0 else "left")
            # Game controller right joystick y-axis.
            JOY_AXIS_RIGHT_Y:
                return "Right joystick " + ("down" if event.axis_value > 0 else "up")
    return base_name

func update_input(label_name: String, button: Button, input: InputEvent, is_joypad: bool):
    # a new key want to be edited, cancel previous
    if is_waiting_key or is_waiting_controller:
        waiting_button.text = old_key_label

    waiting_button = button
    waiting_label_name = label_name
    old_key_label = waiting_button.text
    waiting_button.text = "En attente de touches..."
    input_waiting_change = input
    is_waiting_key = !is_joypad
    is_waiting_controller = is_joypad

func clear_buttons() -> void:
    for child in Main.get_children():
        child.queue_free()

func _on_parameters_changed() -> void:
    clear_buttons()
    setup()

func _on_reset_pressed() -> void:
    SaveController.reset_controls()
    SaveController.save_parameters()
