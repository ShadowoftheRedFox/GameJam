extends MarginContainer
class_name MessageFeed

var transition_time: int = 3
var wait_before_transition: int = 5
var current_transition: float = 0.0

@onready var feed: VBoxContainer = $MarginContainer/ScrollContainer/Feed

func _ready() -> void:
    GameController.global_feed.connect(feed_listener)
    modulate = Color("ffffff00")

func feed_listener(message: String) -> void:
    if message.is_empty():
        return
    
    var msg := Label.new()
    msg.text = message.lstrip(" \t").rstrip(" \t")
    
    feed.add_child(msg)
    
    modulate = Color("ffffff")
    current_transition = transition_time + wait_before_transition

func _process(delta: float) -> void:
    if current_transition == 0:
        return
    
    current_transition -= delta
    if current_transition <= 0:
        current_transition = 0
    
    if current_transition <= transition_time:
        modulate = Color("ffffff" + "%02x" % (
            int(current_transition/float(transition_time) * 255)
        ))
