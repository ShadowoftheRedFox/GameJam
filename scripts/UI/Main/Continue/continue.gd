extends Control

signal back_pressed

@onready var Options: OptionButton = $Main/MarginContainer/VBoxContainer/SaveName/OptionButton
@onready var Error: Label = $Main/MarginContainer/VBoxContainer/Error
@onready var Edit: EditMenu = $Edit

@onready var infos_Difficulty: Label = $Main/MarginContainer/VBoxContainer/Infos/Difficulty
@onready var infos_Size: Label = $Main/MarginContainer/VBoxContainer/Infos/Size
@onready var infos_Gamemode: Label = $Main/MarginContainer/VBoxContainer/Infos/Gamemode

func _ready() -> void:
    check_save()
    SaveController.saves_changed.connect(check_save)
    $Main/MarginContainer/VBoxContainer/Resume.grab_focus()
    
func check_save() -> void:
    # remove everything
    Options.clear()
    if len(SaveController.save_display_names) > 0:
        for i in SaveController.save_display_names.size():
            Options.add_item(SaveController.save_display_names[i], i)
        # enable other buttons
        $Main/MarginContainer/VBoxContainer/Resume.disabled = false
        $Main/MarginContainer/VBoxContainer/Edit.disabled = false
        $Main/MarginContainer/VBoxContainer/Delete.disabled = false
        # default select 0
        Options.select(0)
        # show infos of the save
        var infos = SaveController.get_save_info((SaveController.save_display_names[0]))
        infos_Difficulty.text = "Difficulté : " + infos.get("difficulty", "Inconnue")
        infos_Size.text = "Taille : " + infos.get("map_size", "Inconnue")
        infos_Gamemode.text = "Mode de jeu : " + infos.get("gamemode", "Inconnue")
    else :
        Options.add_item("LabHyrinTical", 0)
        Options.set_item_disabled(0, true)
        # disable other buttons
        $Main/MarginContainer/VBoxContainer/Resume.disabled = true
        $Main/MarginContainer/VBoxContainer/Edit.disabled = true
        $Main/MarginContainer/VBoxContainer/Delete.disabled = true
        infos_Difficulty.text = "Difficulté : Héroïque"
        infos_Size.text = "Taille : Infinie"
        infos_Gamemode.text = "Mode de jeu : Simulation"

func _on_option_button_item_selected(index: int) -> void:
    # show infos of the save when changeing selection
    var infos = SaveController.get_save_info((SaveController.save_display_names[index]))
    infos_Difficulty.text = "Difficulté : " + infos.get("difficulty", "Inconnue")
    infos_Size.text = "Taille : " + infos.get("map_size", "Inconnue")
    infos_Gamemode.text = "Mode de jeu : " + infos.get("gamemode", "Inconnue")

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_resume_pressed() -> void:
    # load and resume game
    var save_display_name = Options.get_item_text(Options.selected)
    GameController.launch_solo(SaveController.get_save_name(save_display_name))
    back_pressed.emit()


func _on_edit_pressed() -> void:
    $Main.hide()
    $Edit.show()
    $Edit/MarginContainer/VBoxContainer/Back.grab_focus()
    # split because we display the difficulty in it
    var save_display_name = Options.get_item_text(Options.selected)
    Edit.get_save.emit(
        save_display_name,
        SaveController.get_save(SaveController.get_save_name(save_display_name))[0]
    )
    
func _on_edit_back_pressed() -> void:
    $Main.show()
    $Edit.hide()
    $Main/MarginContainer/VBoxContainer/Resume.grab_focus()

func _on_delete_pressed() -> void:
    $AcceptDialog.show()


func _on_accept_dialog_confirmed() -> void:
    $AcceptDialog.hide()
    var success = SaveController.delete_save(Options.get_item_text(Options.selected))
    if success == false:
        Error.text = "Une erreur est survenue en essayant d'effacer la sauvegarde"
        await get_tree().create_timer(5.0).timeout
        Error.text = ""


func _on_accept_dialog_canceled() -> void:
        $AcceptDialog.hide()
