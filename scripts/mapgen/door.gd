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

## To stop player when colliding if door closed
@export_flags_2d_physics var layer_block: int = 0b11
## To tell which layer trigger the event
@export_flags_2d_physics var layer_trigger: int = 0b1110

## To get the size of tile and resize to 1x3 tile size
@export var tile_map_layer: TileMapLayer = null:
    get: 
        return tile_map_layer
    set(value):
        tile_map_layer = value
        resize_door()
@onready var collider: CollisionShape2D = $Collider
@onready var door: ColorRect = $Door
@onready var wall: TileMapLayer = $Wall
@onready var static_body: StaticBody2D = $StaticBody
@onready var static_body_collider: CollisionShape2D = $StaticBody/Collider

var connecting_node: Node = null
var door_cleared = true
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # setup collision mask
    self.collision_mask = layer_trigger
    
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
    
    collider.shape.size = Vector2(tile_size.x, 3*tile_size.y)
    static_body_collider.shape.size = Vector2(tile_size.x, 3*tile_size.y)
    
    door.size = Vector2(tile_size.x / 2, 3 * tile_size.y)
    door.position.y = -door.size.y / 2
    
    wall.tile_set.tile_size = tile_size
    wall.position = Vector2(tile_size.x / 2, tile_size.y / 2)

func rotate_door() -> void:
    if !is_node_ready():
        return

    self.rotation = deg_to_rad(float(door_facing * 90))

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
