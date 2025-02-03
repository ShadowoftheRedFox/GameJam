@tool
class_name Door
extends Area2D

enum DoorState {
    OPENED = 0,
    CLOSED = 1,
    WALLED = 2,
    BREAKABLE = 3
}

enum DoorFacing {
    RIGHT = 0,
    DOWN = 1,
    LEFT = 2,
    UP = 3
}

## Layer that the door will be (default: environment)
@export_flags_2d_physics var layer_block: int = 0b1
## Layer that the area will detect
@export_flags_2d_physics var layer_trigger: int = 0b1110

## Size of the door
@export var door_size: Vector2 = Vector2(1, 3):
    get:
        return door_size
    set(value):
        door_size = value
        _resize_door()
        _change_door_state()
        _rotate_door()

@export var door_state: DoorState = DoorState.OPENED:
    get:
        return door_state
    set(value):
        door_state = value
        _change_door_state()
## Show door on this side.
## Each 90° rotation switch to next facing
@export var door_facing: DoorFacing = DoorFacing.RIGHT:
    get:
        return door_facing
    set(value):
        door_facing = value
        _rotate_door()

## Impule given to players only wehn exiting from a upward facing door
@export var up_impulse: float = 20000.0
## If the door does not connect to a new room
@export var connection_less: bool = false
## Amount of hit necessary to break the door open
@export var door_hit: int = 3
var door_hp: int = door_hit

@onready var collider: CollisionShape2D = $Collider
@onready var door: ColorRect = $Door
@onready var wall: TileMapLayer = $Wall
@onready var static_body: StaticBody2D = $StaticBody
@onready var static_body_collider: CollisionShape2D = $StaticBody/Collider
#@onready var border: CollisionShape2D = $StaticBody/Border
@onready var particle: CPUParticles2D = $Collider/CPUParticles2D

## The room that this door connects to
## If null, does not trigger _change_room
## Also note that the connected door will be infered on the door orientation
var body_in_door: Array[Node2D] = []

signal player_entered(player: BasePlayer)
signal player_exited(player: BasePlayer)

# TODO do signal for other things, such as projectiles or buff

signal other_entered(player: Node2D)
signal other_exited(player: Node2D)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    body_entered.connect(_handle_entered)
    body_exited.connect(_handle_exited)
            
    # setup collision mask
    collision_mask = layer_trigger
    
    # get tile size to resize area collider
    _resize_door()
    
    # rotate the door correctly
    _rotate_door()
    
    # change the door state
    _change_door_state()

func _process(_delta: float) -> void:
    if body_in_door.is_empty():
        return
    
    for body in body_in_door:
        var dist: Vector2 = abs(body.global_position - global_position)
        if dist.x > collider.shape.size.x or dist.y > collider.shape.size.y:
            _handle_exited(body)

func _resize_door() -> void:
    if !is_node_ready():
        return
    
    scale = door_size

func _rotate_door() -> void:
    if !is_node_ready():
        return

    rotation = deg_to_rad(float(door_facing * 90))
    match door_facing:
        DoorFacing.LEFT:
            particle.gravity = Vector2(20,0)
        DoorFacing.RIGHT:
            particle.gravity = Vector2(-20,0)
        DoorFacing.UP:
            particle.gravity = Vector2(0,20)
        DoorFacing.DOWN:
            particle.gravity = Vector2(0,-20)

func _change_door_state() -> void:
    if !is_node_ready():
        return

    match door_state:
        DoorState.OPENED:
            static_body.collision_layer = 0
            wall.hide()
            door.hide()
            particle.emitting = true
        DoorState.WALLED:
            static_body.collision_layer = layer_block
            wall.show()
            door.hide()
            particle.emitting = false
        DoorState.CLOSED:
            static_body.collision_layer = layer_block
            wall.hide()
            door.show()
            particle.emitting = false
        _:
            push_error("unknown door state")

func _handle_entered(body: Node2D, _dont_remember: bool = false) -> void:
    if body in body_in_door:
        return
    if body is BasePlayer:
        player_entered.emit(body)
    else:
        other_entered.emit(body)
    body_in_door.append(body)

func _handle_exited(body: Node2D) -> void:  
    if body is BasePlayer:
        player_exited.emit(body)
    else:
        other_exited.emit(body)
    body_in_door.erase(body)
