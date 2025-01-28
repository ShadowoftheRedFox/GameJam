extends Control

@onready var Options: OptionButton = $Host/HBoxContainer4/OptionButton
@onready var Error: Label = $Host/HostError

var IpValid := true
var PortValid := true
var MaxPlayerValid := true
var SaveValid := false

signal host_pressed

func _ready() -> void:
    Save.saves_changed.connect(check_save)
    check_save()


func enable_launch():
    $Host/Launch.disabled = !(IpValid and PortValid and MaxPlayerValid and SaveValid)


func check_save() -> void:
    # remove everything
    Options.clear()
    if len(Save.save_names) > 0:
        var i = 0
        for save_name in Save.save_names:
            Options.add_item(save_name, i)
            i += 1
        # enable other buttons
        SaveValid = true
    else:
        Options.add_item("LabHyrinTical", 0)
        Options.set_item_disabled(0, true)
        # disable other buttons
        SaveValid = false
    enable_launch()


func _on_launch_pressed() -> void:
    Game.launch_multiplayer(Options.get_item_text(Options.selected))
    host_pressed.emit()
    self.hide()


func _on_ip_text_changed(new_text: String) -> void:
    if new_text.is_valid_ip_address():
        Error.text = ""
        Server.change_ip(new_text)
        IpValid = true
    else:
        Error.text = "L'IP fournie n'est pas valide"
        IpValid = false
    enable_launch()


func _on_port_text_changed(new_text: String) -> void:
    if new_text.is_valid_int() and int(new_text) > 0 and int(new_text) < 65535:
        Error.text = ""
        Multi.server.change_port(new_text)
        PortValid = true
    else:
        Error.text = "Le port fourni n'est pas valide"
        PortValid = false
    enable_launch()


func _on_max_player_text_changed(new_text: String) -> void:
    if new_text.is_valid_int():
        if int(new_text) >= 2 and int(new_text) <= 32:
            Error.text = ""
            Multi.server.change_max_player(new_text)
            MaxPlayerValid = true
            enable_launch()
            return
        else:
            Error.text = "Le nombre de joueur maximal doit être supérieur à 1"
    else:
        Error.text = "Le nombre de joueur maximal fourni n'est pas valide"
    MaxPlayerValid = false
    enable_launch()
