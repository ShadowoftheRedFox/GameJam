class_name  EnemieSlime
extends CharacterBody2D

@export var texture_gradient_center: Vector2 = Vector2(0.5, 0.5):
    set(value):
        texture_gradient_center = value
        move_texture()

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

@export var jump_impulse: float = 300.0
@export var speed: float = 30.0
@export var gravity: float = 60
@export var target_range: float = 50000.0

var info: String = "":
    set(value):
        info = value
        if is_node_ready():
            $Info.text = value

var target_player: BasePlayer = null

func _ready() -> void:
    $AnimationPlayer.play("idle")
    info = "Idle"

func move_texture() -> void:
    if !is_node_ready():
        return
    var gradient = sprite.texture as GradientTexture2D
    gradient.fill_from = texture_gradient_center
