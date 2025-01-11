class_name GlobalEnemy
extends CharacterBody2D

@export var jump_impulse: float = 300.0
@export var speed: float = 30.0
@export var gravity: float = 60
@export var target_range: float = 50000.0

var info: String = "":
    set(value):
        info = value
        if is_node_ready() and has_node("Info"):
            $Info.text = value

var target_player: BasePlayer = null
