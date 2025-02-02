extends MarginContainer
class_name MessageFeed

const TimeOut: int = 3
const Wait: int = 5

@onready var feed: VBoxContainer = $MarginContainer/ScrollContainer/Feed

func _ready() -> void:
    Game.global_feed.connect(feed_listener)
    modulate = Color("ffffff00")

func feed_listener(message: String) -> void:
    if message.is_empty():
        return
    
    var msg := Label.new()
    msg.text = message.lstrip(" \t").rstrip(" \t")
    
    feed.add_child(msg)
    
    # animation
    modulate = Color("ffffff")
    var tween: Tween = get_tree().create_tween()
    tween.tween_property(self, "modulate", Color.TRANSPARENT, TimeOut).set_ease(Tween.EASE_OUT).set_delay(Wait)
    
