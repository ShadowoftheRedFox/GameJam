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
    "Controls": [],
    "Sounds": {
        "music": 100,
        "sfx": 100,
        "entities": 100
    }
}

signal saves_changed
signal parameters_changed


#### Load game data ####
func _init() -> void:
    
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
    if save_amount == 0:
        return
    
    # get the save names
    for key_name in general_config.get_section_keys("Save_names"):
        save_display_names.append(general_config.get_value("Save_names", key_name, key_name))
        save_names.append(key_name)
    
    #print("Found ", len(save_names), " saves")
    saves_changed.emit()
    parameters_changed.emit()
    
func _ready() -> void:
    #if !create_new_save("ploof"):
        #printerr("Error while saving")
    #if !delete_save("ploof"):
        #printerr("Error while deleting")
    #print("Ploof exists: ", is_save_name("Ploof"))
    pass

#### Parameters save ####

func setup_parameters() -> void:
    general_config.set_value("Multiplayer", "name", "Player" + str(randi()))
    general_config.set_value("Multiplayer", "color", Color.BLUE.to_html(false))
    
    # save each action and it's default key
    var input_map = InputMap.get_actions().filter(func(s: String): return !s.begins_with("ui_"))
    for input_name in input_map:
        var event_key: InputEvent = InputMap.action_get_events(input_name)[0]
        general_config.set_value("Controls", input_name, event_key.as_text())
    
    general_config.set_value("Sounds", "music", 100)
    general_config.set_value("Sounds", "sfx", 100)
    general_config.set_value("Sounds", "entities", 100)

func get_parameters() -> void:
    parameters.Multiplayer.name = general_config.get_value("Multiplayer", "name", "Player0")
    parameters.Multiplayer.name = general_config.get_value("Multiplayer", "name", "Player0")
    
    # get the controls overrides
    for key_name in general_config.get_section_keys("Controls"):
        parameters.Controls.append([key_name, general_config.get_value("Controls", key_name, "z")])
    
    parameters.Sounds.music = int(general_config.get_value("Sounds", "music", 100))
    parameters.Sounds.sfx = int(general_config.get_value("Sounds", "sfx", 100))
    parameters.Sounds.entities = int(general_config.get_value("Sounds", "entities", 100))
    override_input_map()

func save_control(label_name: String, key: String) -> void:
    var index = 0
    for pair in parameters.Controls:
        if pair[0] == label_name:
            parameters.Controls[index][1] = key
            save_parameters()
            override_input_map()
            return
        index += 1
    
    parameters.Controls.append([label_name, key])
    save_parameters()
    override_input_map()

func override_input_map() -> void:
    for pair in parameters.Controls:
        var event := InputEventKey.new()
        event.set_keycode(OS.find_keycode_from_string(pair[1]))
        
        if InputMap.has_action(pair[0]):
            InputMap.action_erase_events(pair[0])
            InputMap.action_add_event(pair[0], event)
        else:
            InputMap.add_action(pair[0])
            InputMap.action_add_event(pair[0], event)
    parameters_changed.emit()

func save_parameters() -> void:
    general_config.set_value("Multiplayer", "name", parameters.Multiplayer.name)
    general_config.set_value("Multiplayer", "color", parameters.Multiplayer.color)

    # if array empty, load from InputMap
    if len(parameters.Controls) == 0:
        var input_map = InputMap.get_actions().filter(func(s: String): return !s.begins_with("ui_"))
        for input_name in input_map:
            var event_key: InputEvent = InputMap.action_get_events(input_name)[0]
            general_config.set_value("Controls", input_name, event_key.as_text())
    else:
        for pair in parameters.Controls:
            general_config.set_value("Controls", pair[0], pair[1])

    general_config.set_value("Sounds", "music", parameters.Sounds.music)
    general_config.set_value("Sounds", "sfx", parameters.Sounds.sfx)
    general_config.set_value("Sounds", "entities", parameters.Sounds.entities)
    
    for pair in parameters.Controls:
        general_config.set_value("Controls", pair[0], pair[1])
    
    general_config.save(CONFIG_PATH)

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

# TODO edit argument as needed
func create_new_save(save_name: String, _content: String = "") -> bool:
    if !is_save_name(save_name):
        return false

    # edit variable to find the save file
    general_config.set_value("Save_names", save_name, save_name)
    general_config.set_value("General", "save_amount", len(save_names)+1)
    save_names.append(save_name)
    save_display_names.append(save_name)
    
    
    # create the save file
    general_save_file = FileAccess.open(SAVE_PATH + save_name + ".save", FileAccess.WRITE_READ)
    
    # saving our data
    general_save_file.store_string(_content)
    
    # we saved our data, close
    general_save_file.close()
    general_config.save(CONFIG_PATH)
    print("Successfully saved ", save_name)
    saves_changed.emit()
    return true

# TODO useless rn, return more data about the save (difficulty, map size, ...)
func get_saves() -> Array[String]:
    return save_names
    
func get_save(save_name: String) -> Array[Dictionary]:
    if !is_save_name(save_name):
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
    
    var save_path = SAVE_PATH + save_name + ".save"
    var err := DirAccess.remove_absolute(save_path)
    if err != OK:
        printerr("Failed to delete save file : ", save_name)
        return false
    
    save_display_names.erase(get_save_display_name(save_name))
    save_names.erase(save_name)
    general_config.erase_section_key("Save_names", save_name)
    general_config.set_value("General", "save_amount", len(save_names))
    general_config.save(CONFIG_PATH)
    saves_changed.emit()
    return true
