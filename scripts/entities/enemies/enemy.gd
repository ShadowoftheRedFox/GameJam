class_name GlobalEnemy
extends CharacterBody2D

@export_category("Movements")
@export var jump_impulse: float = 100.0
@export var speed: float = 30.0
@export var gravity: float = 980.0
@export var target_range: float = 80000.0

@export_category("Stats")
@export var HP_MAX: int = 100
var hp: int = HP_MAX:
    set(value):
        hp = value
        if is_node_ready():
            hp_label.text = str(hp)
@export var atk: int = 3
@export_range(0, 1) var CRIT_RATE: float = 0.1
@export var CRIT_MULT: int = 2
## Attack/s
@export var atk_speed: float = 1.5
@export var friendly_fire: bool = false

@export_category("Animations")
@export var disappear_on_death: bool = true
## Time before the node is removed (with animation) in seconds
@export var disappearance_time: int = 5
var disappearance_timer: float = float(disappearance_time)

var state_machine: StateMachine
var machine_less: bool = false

var attack_box: Area2D
var body_collider: CollisionShape2D

var animation_sprite: AnimatedSprite2D
var animation_player: AnimationPlayer

var hp_label: Label
var dmg_spawn: Marker2D

@warning_ignore("unused_signal")
signal animate(animation: String)
signal damaged(attacker: Node2D, damage: int, crit: bool)
@warning_ignore("unused_signal")
signal ondeath(killer: Node2D)

func _ready() -> void:
    assert(state_machine != null and !machine_less, "Global enemies must include a state machine, or say they don't use one")
    assert(attack_box != null and atk > 0, "Global enemies must have a attack hitbox or deal 0 damages")
    assert(body_collider != null, "Global enemies must have a hitbox")
    assert(dmg_spawn != null, "Global enemies must have a dmg_spawn marker")
    
    damaged.connect(handle_damage)

func handle_damage(attacker: Node2D, damage: int, crit: bool = false) -> void:
    if !machine_less:
        state_machine._transition_to_next_state("Damaged", {"damages": damage, "crit": crit, "attacker": attacker})

var info: String = "":
    set(value):
        info = value
        if is_node_ready() and has_node("Info"):
            $Info.text = value

var target_player: BasePlayer = null
