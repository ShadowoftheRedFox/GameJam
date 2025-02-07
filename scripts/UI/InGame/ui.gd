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
            hp_label.text = hp + "/" + str(player.HP_MAX)

@onready var pos_label: Label = $MarginContainer/Pos
var pos: String = "0, 0":
    set(value):
        pos = value
        if is_node_ready():
            pos_label.text = pos
            
@onready var death_counter: Label = $MarginContainer/DeathCounter
@onready var player: BasePlayer = $"../../.."
@onready var message_feed: MessageFeed = $MarginContainer/FeedContainer
@onready var prompts: MarginContainer = $MarginContainer/Prompts

signal start_counter(time: int)
var time_remaining: float = 0.0

func _ready() -> void:
    if player != Game.main_player_instance:
        return
    
    hp_label.text = hp
    pos_label.text = pos
    start_counter.connect(display_timer)
    Game.game_end.connect(show_end_screen)
    
    # make prompts disappear
    var tween: Tween = get_tree().create_tween()
    tween.tween_property(prompts, "modulate", Color.TRANSPARENT, 1).set_ease(Tween.EASE_OUT).set_delay(10)
    
    await tween.finished
    prompts.queue_free()

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

func show_end_screen(_id: int) -> void:
    $MarginContainer.hide()
    $Scores.hide()
    $EndGame.show()
