extends Node

# FileAccess:   https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
# Config:       https://docs.godotengine.org/en/stable/classes/class_configfile.html

var general_config := ConfigFile.new()
var save_names: Array[String] = []
var save_id_count: int = 0

var general_save_data: Array[Dictionary] = []
var general_save_file: FileAccess = null

# TODO change save name to id to save name FIXED to save name editablea

@warning_ignore("unused_signal") signal saves_changed

#### Load game data ####
func _init() -> void:
    
    # first, we look into the config file, and look for the amount of save
    # if amount > 0, get(saveN) for teh name, and load the saveN.save
    
    # Load data from a file.
    var err = general_config.load("user://saves.cfg")
    # If the file didn't load, ignore it.
    if err != OK:
        print("Creating saves config file for the first time...")
        general_config.set_value("General", "save_amount", 0)
        general_config.set_value("General", "save_id", 0)
        general_config.save("user://saves.cfg")
        return
    
    # get the amount of saved game
    var save_amount = general_config.get_value("General", "save_amount", 0)
    save_id_count = general_config.get_value("General", "save_id", 0)
    if save_amount == 0:
        return
    
    # get the save names
    for key_name in general_config.get_section_keys("Save_names"):
        #var save_id = general_config.get_value("Save_names", key_name, 0)
        save_names.append(key_name)
    
    print("Found ", len(save_names), " saves")
    printerr(save_names)
    
func _ready() -> void:
    #if !create_new_save("ploof"):
        #printerr("Error while saving")
    #if !delete_save("ploof"):
        #printerr("Error while deleting")
    #print("Ploof exists: ", is_save_name("Ploof"))
    pass

#### Game save ####
func is_save_name(save_name: String) -> bool:
    return save_names.has(save_name)

# TODO edit argument as needed
func create_new_save(save_name: String, _content: String = "") -> bool:
    if is_save_name(save_name):
        return false

    # edit variable to find the save file
    save_id_count += 1
    general_config.set_value("Save_names", save_name, save_id_count)
    general_config.set_value("General", "save_amount", len(save_names)+1)
    general_config.set_value("General", "save_id", save_id_count)
    save_names.append(save_name)
    
    # create the save file
    general_save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.WRITE_READ)
    
    # saving our data
    general_save_file.store_string(_content)
    
    # we saved our data, close
    general_save_file.close()
    general_config.save("user://saves.cfg")
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
    general_save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ)
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
    
    general_save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ)
    if general_save_file == null:
        printerr("Error while trying to open asve file : ", save_name)
        return ""
        
    var save_content := general_save_file.get_as_text()
    general_save_file.close()
    
    return save_content
    
func update_save(save_name: String, _content: String = "") -> bool:
    if is_save_name(save_name):
        return false
   
    # open the save file
    general_save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ_WRITE)
    if general_save_file == null:
        printerr("Error while opening save file '",save_name,"' for update")
        return false
    
    # saving our data
    general_save_file.store_string(_content)
    
    # we saved our data, close
    general_save_file.close()
    print("Successfully updated ", save_name)
    return true
    
func delete_save(save_name: String) -> bool:
    if !is_save_name(save_name):
        return false
    
    var save_path = "user://" + save_name + ".save"
    #var save_id = save_ids[save_names.find(save_name)]
    var err := DirAccess.remove_absolute(save_path)
    if err != OK:
        printerr("Failed to delete save file : ", save_name)
        return false
    
    save_names.erase(save_name)
    general_config.erase_section_key("Save_names", save_name)
    general_config.set_value("General", "save_amount", len(save_names))
    general_config.save("user://saves.cfg")
    saves_changed.emit()
    return true
