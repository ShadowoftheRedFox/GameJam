class_name PlayerUI
extends Control

@onready var hp_label: Label = $MarginContainer/HP
var hp: String = "HP : unset":
    set(value):
        if (value as String).begins_with("HP : "):
            hp = value
        else:
            hp = "HP : " + str(int(value))
        if is_node_ready():
            hp_label.text = hp
            
@onready var death_counter: Label = $MarginContainer/DeathCounter
@onready var player: BasePlayer = $"../../.."
@onready var message_feed: MessageFeed = $MarginContainer/FeedContainer

signal start_counter(time: int)
var time_remaining: float = 0.0

func _ready() -> void:
    hp_label.text = hp
    start_counter.connect(display_timer)

func _physics_process(delta: float) -> void:
    if !death_counter.visible:
        return
        
    time_remaining -= delta
    death_counter.text = "Vous êtes mort\n" + str(int(time_remaining)) + " secondes restantes"
    if time_remaining <= 0:
        player.respawn.emit()
        death_counter.hide()
        time_remaining = 0.0

func display_timer(timer: int) -> void:
    time_remaining = float(timer)
    death_counter.show()
    death_counter.text = "Vous êtes mort\n" + str(timer) + " secondes restantes"
