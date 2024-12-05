extends Control

@onready var Launch: Button = $Join/Launch
@onready var Error: Label = $Join/JoinError
@onready var IpText: TextEdit = $Join/HBoxContainer/IP
@onready var PortText: TextEdit = $Join/HBoxContainer2/Port

var IpValid := true
var PortValid := true

func _ready() -> void:
    enable_launch()

func enable_launch() -> void:
    Launch.disabled = !(IpValid and PortValid)

func _on_launch_pressed() -> void:
    GameController.join_multiplayer()


func _on_ip_text_changed() -> void:
    if IpText.text.is_valid_ip_address():
        Error.text = ""
        Server.change_ip(IpText.text)
        IpValid = true
    else:
        Error.text = "L'IP fournie n'est pas valide"
        IpValid = false
    enable_launch()


func _on_port_text_changed() -> void:
    if PortText.text.is_valid_int() and int(PortText.text) > 0 and int(PortText.text) < 65535:
        Error.text = ""
        Server.change_port(PortText.text)
        PortValid = true
    else:
        Error.text = "Le port fourni n'est pas valide"
        PortValid = false
    enable_launch()
