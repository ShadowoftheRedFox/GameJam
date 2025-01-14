extends Node

# FileAccess:   https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
# Config:       https://docs.godotengine.org/en/stable/classes/class_configfile.html

const CONFIG_PATH = "user://saves.cfg"
const SAVE_PATH = "user://"

var general_config := ConfigFile.new()
var save_names: Array[String] = []
var save_display_names: Array[String] = []

var general_save_data: Array[Dictionary] = []
var general_save_file: FileAccess = null

var parameters := {
    "Multiplayer": {
        "name": "Player0",
        "color": "0000ff"
    },
    "Controls": {
        "key": [],
        "controller": []   
    },
    "Sounds": {
        "music": 100,
        "sfx": 100,
        "entities": 100
    }
}

signal saves_changed
signal parameters_changed


#### Load game data ####
#func _init() -> void:
func _ready() -> void:
    # first, we look into the config file, and look for the amount of save
    # if amount > 0, get(saveN) for the name, and load the saveN.save
    
    # Load data from a file.
    var err = general_config.load(CONFIG_PATH)
    # If the file didn't load, ignore it.
    if err != OK:
        print("Creating saves config file for the first time...")
        general_config.set_value("General", "save_amount", 0)
        setup_parameters()
        general_config.save(CONFIG_PATH)
        return
    
    get_parameters()
    
    # get the amount of saved game
    var save_amount = general_config.get_value("General", "save_amount", 0)
    if save_amount > 0:
        # get the save names
        for key_name in general_config.get_section_keys("Save_names"):
            save_display_names.append(general_config.get_value("Save_names", key_name, key_name))
            save_names.append(key_name)
        saves_changed.emit()
    
    #print("Found ", len(save_names), " saves")
    
    
#func _ready() -> void:
    #if !create_new_save("ploof"):
        #printerr("Error while saving")
    #if !delete_save("ploof"):
        #printerr("Error while deleting")
    #print("Ploof exists: ", is_save_name("Ploof"))
    
    #parameters_changed.connect(p)
    #pass
func p(): 
    printerr("param change")
#### Parameters save ####

func setup_parameters() -> void:
    general_config.set_value("Multiplayer", "name", "Player" + str(randi()))
    general_config.set_value("Multiplayer", "color", Color.BLUE.to_html(false))
    
    # save each action and it's default key
    var input_map = get_own_event()
    for input_name in input_map:
        var event_actions = InputMap.action_get_events(input_name)
        var event_key: InputEvent = event_actions[0] if event_actions.size() >= 1 else null
        var event_controller: InputEvent = event_actions[1] if event_actions.size() >= 2 else null
        general_config.set_value("Controls_key", input_name, str(event_key))
        general_config.set_value("Controls_controller", input_name, str(event_controller))
    
    general_config.set_value("Sounds", "music", 100)
    general_config.set_value("Sounds", "sfx", 100)
    general_config.set_value("Sounds", "entities", 100)
    
    parameters_changed.emit()

func get_parameters() -> void:
    parameters.Multiplayer.name = general_config.get_value("Multiplayer", "name", "Player0")
    parameters.Multiplayer.name = general_config.get_value("Multiplayer", "name", "Player0")
    
    # get the controls overrides
    for key_name in general_config.get_section_keys("Controls_key"):
        parameters.Controls.key.append([key_name, general_config.get_value("Controls_key", key_name, "")])
    for key_name in general_config.get_section_keys("Controls_controller"):
        parameters.Controls.controller.append([key_name, general_config.get_value("Controls_controller", key_name, "")])

    parameters.Sounds.music = int(general_config.get_value("Sounds", "music", 100))
    parameters.Sounds.sfx = int(general_config.get_value("Sounds", "sfx", 100))
    parameters.Sounds.entities = int(general_config.get_value("Sounds", "entities", 100))
    
    override_input_map()
    parameters_changed.emit()
    
func reset_controls() -> void:
    InputMap.load_from_project_settings()
    parameters.Controls.key = []
    parameters.Controls.controller = []
    
    var input_map = InputMap.get_actions().filter(func(s: String): return !s.begins_with("ui_"))

    # for each of these, add a button and get the key
    for input_name in input_map:
        var event_actions = InputMap.action_get_events(input_name)
        var event_key: String = str(event_actions[0]) if event_actions.size() >= 1 else "(Aucun)"
        var event_controller: String = str(event_actions[1]) if event_actions.size() >= 2 else "(Aucun)"
        parameters.Controls.key.append([input_name, event_key])
        parameters.Controls.controller.append([input_name, event_controller])
    
    override_input_map()

func save_control(label_name: String, key: String, is_joypad: bool) -> void:
    if is_joypad:
        for index in parameters.Controls.controller.size():
            if parameters.Controls.controller[index][0] == label_name:
                parameters.Controls.controller[index][1] = key
                override_input_map()
                save_parameters()
                return
        
        parameters.Controls.controller.append([label_name, key])
    else:
        for index in parameters.Controls.key.size():
            if parameters.Controls.key[index][0] == label_name:
                parameters.Controls.key[index][1] = key
                override_input_map()
                save_parameters()
                return
        
        parameters.Controls.key.append([label_name, key])
        
    override_input_map()
    save_parameters()

func override_input_map() -> void:
    # parse key input and put it in input map correctly
    for pair in parameters.Controls.key:
        var event_key := parse_input_event_key(pair[1])
        
        if InputMap.has_action(pair[0]):
            InputMap.action_erase_events(pair[0])
            InputMap.action_add_event(pair[0], event_key)
        else:
            InputMap.add_action(pair[0])
            InputMap.action_add_event(pair[0], event_key)
            
    # parse joypad input and put it in input map correctly
    for pair in parameters.Controls.controller:
        if parse_get_input_type(pair[1]) == InputEventJoypadButton:
            var event_controller: InputEventJoypadButton = parse_input_event_joypad_button(pair[1])
            InputMap.action_add_event(pair[0], event_controller)
        elif parse_get_input_type(pair[1]) == InputEventJoypadMotion:
            var event_motion: InputEventJoypadMotion = parse_input_event_joypad_motion(pair[1])
            InputMap.action_add_event(pair[0], event_motion)
            
    parameters_changed.emit()

func save_parameters() -> void:
    general_config.set_value("Multiplayer", "name", parameters.Multiplayer.name)
    general_config.set_value("Multiplayer", "color", parameters.Multiplayer.color)

    # if array empty, load from InputMap
    if parameters.Controls.key.size() == 0:
        var input_map = get_own_event()
        for input_name in input_map:
            var event_key = InputMap.action_get_events(input_name)[0]
            general_config.set_value("Controls_key", input_name, str(event_key))
    else:
        for pair in parameters.Controls.key:
            general_config.set_value("Controls_key", pair[0], pair[1])
    
    if parameters.Controls.controller.size() == 0:
        var input_map = get_own_event()
        for input_name in input_map:
            var event_key = InputMap.action_get_events(input_name)[1] if InputMap.action_get_events(input_name).size() >= 2 else null 
            general_config.set_value("Controls_controller", input_name, str(event_key))
    else:
        for pair in parameters.Controls.controller:
            general_config.set_value("Controls_controller", pair[0], pair[1])

    general_config.set_value("Sounds", "music", parameters.Sounds.music)
    general_config.set_value("Sounds", "sfx", parameters.Sounds.sfx)
    general_config.set_value("Sounds", "entities", parameters.Sounds.entities)
    
    general_config.save(CONFIG_PATH)

func parse_get_input_type(data: String) -> Variant:
    if data.begins_with("InputEventKey: "):
        return InputEventKey
    elif data.begins_with("InputEventJoypadButton: "):
        return InputEventJoypadButton
    elif data.begins_with("InputEventJoypadMotion: "):
        return InputEventJoypadMotion
    else:
        return null

func parse_input_event_key(data: String) -> InputEventKey:
    if !data.begins_with("InputEventKey: "):
        push_error("given data string is not input event key: ", data)
        return null
    
    var event := InputEventKey.new()
    # a base string looks like this: 
    ## InputEventKey: keycode=74 (J), mods=none, physical=true, location=unspecified, pressed=false, echo=false
    # we will erase the input event key and parse each member
    var members : PackedStringArray = data.erase(0, len("InputEventKey: ")).split(", ", false, 6)
    
    # parse physical with contains
    # then parse keycode, using the int() property, then trhough OS to prevent warning "cast to enum"
    if members[2].contains("true"):
        @warning_ignore("int_as_enum_without_cast")
        event.physical_keycode = int(members[0])
    else:
        @warning_ignore("int_as_enum_without_cast")
        event.keycode = int(members[0])
    
    # TODO parse mods, location
    return event

func parse_input_event_joypad_button(data: String) -> InputEventJoypadButton:
    if !data.begins_with("InputEventJoypadButton: "):
        push_error("given data string is not input event joypad button: ", data)
        return null
    
    var event := InputEventJoypadButton.new()
    # a base string looks like this: 
    ## InputEventJoypadButton: button_index=1, pressed=true, pressure=0.00
    # we will erase the input event key and parse each member
    var members : PackedStringArray = data.erase(0, len("InputEventJoypadButton: ")).split(", ", false, 3)
    # parse button_index using int property
    @warning_ignore("int_as_enum_without_cast")
    event.button_index = int(members[0]) 
    # parse pressed
    event.pressed = members[1].contains("true")
    # parse pressure using float property
    event.pressure = float(members[2])
    
    return event

func parse_input_event_joypad_motion(data: String) -> InputEventJoypadMotion:
    if !data.begins_with("InputEventJoypadMotion: "):
        push_error("given data string is not input event key: ", data)
        return null
    
    var event := InputEventJoypadMotion.new()
    # a base string looks like this: 
    ## InputEventJoypadMotion: axis=1, axis_value=-1.00
    # we will erase the input event key and parse each member
    var members : PackedStringArray = data.erase(0, len("InputEventJoypadMotion: ")).split(", ", false, 2)
    # parse axis 
    @warning_ignore("int_as_enum_without_cast")
    event.axis = int(members[0])
    # parse axis value, spliting on equal because it seems to break the to_float
    event.axis_value = members[1].split("=")[1].to_float()
        
    return event
    
func get_own_event() -> Array[StringName]:
    return InputMap.get_actions().filter(func(s: String): return !s.begins_with("ui_"))

#### Game save ####
func is_save_name(save_name: String) -> bool:
    return save_names.has(save_name)

func is_save_display_name(save_display_name: String) -> bool:
    return save_display_names.has(save_display_name)

func get_save_display_name(save_name: String) -> String:
    if !is_save_name(save_name):
        return save_name
    return save_display_names[save_names.find(save_name)]

func get_save_name(save_display_name: String) -> String:
    if !is_save_display_name(save_display_name):
        return save_display_name
    return save_names[save_display_names.find(save_display_name)] 

func create_new_save(save_name: String, content: String = "") -> bool:
    # edit variable to find the save file
    general_config.set_value("Save_names", save_name, save_name)
    general_config.set_value("General", "save_amount", len(save_names)+1)
    save_names.append(save_name)
    save_display_names.append(save_name)
    
    
    # create the save file
    general_save_file = FileAccess.open(SAVE_PATH + save_name + ".save", FileAccess.WRITE_READ)
    
    # saving our data
    general_save_file.store_string(content)
    
    # we saved our data, close
    general_save_file.close()
    general_config.save(CONFIG_PATH)
    print("Successfully saved ", save_name)
    saves_changed.emit()
    return true

func get_save_info(save_name: String) -> Dictionary:
    if !is_save_name(save_name):
        return {}
    
    var data := get_save(save_name)[0]
    
    return {
        "map_size": GameController.MapSizesNames[data.get("map_size", 0)],
        "difficulty": GameController.DifficultiesNames[data.get("difficulty", 0)],
        "gamemode": GameController.GameModesNames[data.get("gamemode", 0)]
    }
    
func get_save(save_name: String) -> Array[Dictionary]:
    if !is_save_name(save_name):
        printerr("not a save game")
        return []
    
    var file_data: Array[Dictionary] = []
    
    # open the needed save file
    general_save_file = FileAccess.open(SAVE_PATH + save_name + ".save", FileAccess.READ)
    if general_save_file == null:
        printerr("Error while trying to open asve file : ", save_name)
        return []
    
    while general_save_file.get_position() < general_save_file.get_length():
        var json_string = general_save_file.get_line()

        # Creates the helper class to interact with JSON.
        var json = JSON.new()

        # Check if there is any error while parsing the JSON string, skip in case of failure.
        var parse_result = json.parse(json_string)
        if not parse_result == OK:
            print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
            continue
        file_data.append(json.data)
    
    return file_data
    
func get_save_raw(save_name: String) -> String:
    if !is_save_name(save_name):
        return ""
    
    general_save_file = FileAccess.open(SAVE_PATH + save_name + ".save", FileAccess.READ)
    if general_save_file == null:
        printerr("Error while trying to open asve file : ", save_name)
        return ""
        
    var save_content := general_save_file.get_as_text()
    general_save_file.close()
    
    return save_content


enum UpdateActions {
    CHANGE_DISPLAY_NAME = 0,
    CHANGE_SAVE_CONTENT = 1
}
func update_save(save_name: String, args: Dictionary = {}) -> bool:
    if !is_save_name(save_name):
        return false
    
    if args.has(UpdateActions.CHANGE_DISPLAY_NAME):
        var arg_data = args.get(UpdateActions.CHANGE_DISPLAY_NAME)
        if !(arg_data is String):
            push_error("Expected String from CHANGE_SAVE_CONTENT")
            return false
        general_config.set_value("Save_names", save_name, arg_data)
        save_display_names[save_names.find(save_name)] = arg_data
        general_config.save(CONFIG_PATH)
    
    if args.has(UpdateActions.CHANGE_SAVE_CONTENT):
        if !(args.get(UpdateActions.CHANGE_SAVE_CONTENT) is String):
            push_error("Expected string from CHANGE_SAVE_CONTENT")
            return false
        
        # open the save file
        general_save_file = FileAccess.open(SAVE_PATH + save_name + ".save", FileAccess.READ_WRITE)
        if general_save_file == null:
            printerr("Error while opening save file '",save_name,"' for update")
            return false
        
        # saving our data
        general_save_file.store_string(args.get(UpdateActions.CHANGE_SAVE_CONTENT))
        
        # we saved our data, close
        general_save_file.close()
        print("Successfully updated ", save_name)
        
    saves_changed.emit()
    return true
    
func save_game(save_name: String) -> bool:
    print("Saving...")
    # TODO save game
    var _save = SaveController.get_save(save_name)
    
    print("Saved")
    return true
    
func delete_save(save_name: String) -> bool:
    if !is_save_name(save_name):
        return false
    
    var dir = DirAccess.open(SAVE_PATH)
    var save_path: String = save_name + ".save"
    print(dir.remove_absolute(save_path))
    
    if !dir.file_exists(save_name + ".save"):
        printerr("File does not exists : ", save_path)
        return false
        
    var err := dir.remove(save_path)
    if err != OK:
        printerr("Failed to delete save file : ", save_path, " ", error_string(err))
        return false
    
    save_display_names.erase(get_save_display_name(save_name))
    save_names.erase(save_name)
    general_config.erase_section_key("Save_names", save_name)
    general_config.set_value("General", "save_amount", len(save_names))
    general_config.save(CONFIG_PATH)
    saves_changed.emit()
    return true
