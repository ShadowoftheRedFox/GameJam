extends Control

@onready var margin_top: MarginContainer = $Main/Top
@onready var margin_bottom: MarginContainer = $Main/Bottom
@onready var main: VBoxContainer = $Main

const scroll_speed = 50.0
var old_screen_size = 0
var ending = false
    
func end() -> void:
    print("credits ending...")
    ending = true
    TransitionController.current_scene = self
    TransitionController._deferred_change_scene("res://scenes/UI/Main/MainMenu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # resize margin is needed
    old_screen_size = get_tree().root.size.y
    get_tree().root.size_changed.connect(resize_margin)
    # setup margin size so everything is outside the screen on start and end
    margin_top.add_theme_constant_override("margin_bottom", old_screen_size)
    margin_bottom.add_theme_constant_override("margin_bottom", old_screen_size)

func resize_margin() -> void:
    var screen_size = get_tree().root.size.y
    margin_top.add_theme_constant_override("margin_bottom", screen_size)
    margin_bottom.add_theme_constant_override("margin_bottom", screen_size)
    main.position.y -= screen_size - old_screen_size
    old_screen_size = screen_size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    main.position.y -= scroll_speed * _delta
    
    if !ending and \
        (-main.position.y > main.size.y - old_screen_size or \
        Input.is_action_just_pressed("Pause") or \
        Input.is_action_just_pressed("ui_cancel")):
        end()
