@tool
class_name Door
extends Area2D

enum DoorState {
    OPENED = 0,
    CLOSED = 1,
    WALLED = 2
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
        resize_door()
        change_door_state()
        rotate_door()

## To get the size of tile and resize to 1x3 tile size
@export var tile_map_layer: TileMapLayer = null:
    get: 
        return tile_map_layer
    set(value):
        tile_map_layer = value
        resize_door()

@export var door_state: DoorState = DoorState.OPENED:
    get:
        return door_state
    set(value):
        door_state = value 
        change_door_state()
## Show door on this side.
## Each 90° rotation switch to next facing
@export var door_facing: DoorFacing = DoorFacing.RIGHT:
    get:
        return door_facing
    set(value):
        door_facing = value
        rotate_door()

## Impule given to players only wehn exiting from a upward facing door
@export var up_impulse: float = 2000.0

@onready var collider: CollisionShape2D = $Collider
@onready var door: ColorRect = $Door
@onready var wall: TileMapLayer = $Wall
@onready var static_body: StaticBody2D = $StaticBody
@onready var static_body_collider: CollisionShape2D = $StaticBody/Collider

signal player_entered(player: BasePlayer)
signal player_exited(player: BasePlayer)

# TODO do signal for other things, such as projectiles or buff

signal other_entered(player: Node2D)
signal other_exited(player: Node2D)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # upward impulse
    body_entered.connect(handle_entered)
    body_exited.connect(handle_exited)
    
    # setup collision mask
    collision_mask = layer_trigger
    
    # get tile size to resize area collider
    resize_door()
    
    # rotate the door correctly
    rotate_door()
    
    # change the door state
    change_door_state()

func resize_door() -> void:
    if !is_node_ready():
        return
    
    var tile_size := Vector2(64, 64)
    if tile_map_layer != null:
        tile_size = tile_map_layer.tile_set.tile_size
    
    collider.shape.size = Vector2(tile_size.x * door_size.x / 2, door_size.y * tile_size.y)
    collider.position.x = -door.size.y / 2
    
    static_body_collider.shape.size = Vector2(tile_size.x * door_size.x, door_size.y * tile_size.y)
    
    door.size = Vector2(tile_size.x * door_size.x / 2, door_size.y * tile_size.y)
    door.position.y = -door.size.y / 2
    
    wall.tile_set.tile_size = tile_size
    wall.position = Vector2(tile_size.x * door_size.x / 2, tile_size.y * door_size.y / 2)

func rotate_door() -> void:
    if !is_node_ready():
        return

    rotation = deg_to_rad(float(door_facing * 90))

func change_door_state() -> void:
    if !is_node_ready():
        return

    match door_state:
        DoorState.OPENED:
            static_body.collision_layer = 0
            wall.hide()
            door.hide()
        DoorState.WALLED:
            static_body.collision_layer = layer_block
            wall.show()
            door.hide()
        DoorState.CLOSED:
            static_body.collision_layer = layer_block
            wall.hide()
            door.show()
        _:
            push_error("unknown door state")

func handle_entered(body: Node2D) -> void:
    if body is BasePlayer:
        player_entered.emit(body)
    else:
        other_entered.emit(body)

func handle_exited(body: Node2D) -> void:
    if body is BasePlayer:
        player_exited.emit(body)
    else:
        other_exited.emit(body)

#func upward_impulse(body: Node2D) -> void:
    #if body is BasePlayer and door_facing == DoorFacing.UP:
        #var player: BasePlayer = body
        #player.velocity.y -= up_impulse
        #player.move_and_slide()
