extends Control

@onready var Options: OptionButton = $Host/HBoxContainer4/OptionButton
@onready var Error: Label = $Host/HostError

func _ready() -> void:
    check_save()
    SaveController.saves_changed.connect(check_save, ConnectFlags.CONNECT_PERSIST)
    
func check_save() -> void:
    # remove everything
    Options.clear()
    if len(SaveController.save_names) > 0:
        var i = 0
        for save_name in SaveController.save_names:
            Options.add_item(save_name, i)
            i += 1
        # enable other buttons
        $Host/Launch.disabled = false
    else :
        Options.add_item("LabHyrinTical", 0)
        Options.set_item_disabled(0, true)
        # disable other buttons
        $Host/Launch.disabled = true


func _on_launch_pressed() -> void:
    # TODO load save and start server
    pass # Replace with function body.
