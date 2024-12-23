extends Control

@onready var Launch: Button = $Join/Launch
@onready var Error: Label = $Join/JoinError

var IpValid := true
var PortValid := true

signal join_pressed

func _ready() -> void:
    enable_launch()

func enable_launch() -> void:
    Launch.disabled = !(IpValid and PortValid)

func _on_launch_pressed() -> void:
    if !GameController.join_multiplayer():
        Error.text = "Erreur lors de la connexion à l'hôte"
        return
        
    join_pressed.emit()
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
        Server.change_port(new_text)
        PortValid = true
    else:
        Error.text = "Le port fourni n'est pas valide"
        PortValid = false
    enable_launch()
