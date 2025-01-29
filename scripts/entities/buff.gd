class_name Buff
extends Node2D

enum BuffPreset {
    NONE = -1,
    
    CUSTOM = 0,
    SPEED_BOOSTER = 1,
    SPEED_UPGRADER = 2,
    HEALTH_BOOSTER = 3,
    HEALTH_UPGRADER = 4,
    JUMP_UPGRADER = 5,
    DASH_UPGRADER = 6,
    
    MAX = 7
}
const buff_title: Array[String] = [
    "Mystère",
    "Boost de vitesse",
    "Amélioration de vitesse",
    "Boost de vie",
    "Amélioration de vie",
    "Plus de saut",
    "Plus de dash"
]
const buff_description: Array[String] = [
    "Tentez votre chance!",
    "Augmente votre vitesse de déplacement",
    "Augmente votre vitesse actuelle de 20%",
    "Augmente vos points de vie",
    "Augmente vos points de vie actuels de 20%",
    "Octroie un saut supplémentaire",
    "Octroie un élan supplémentaire"
]

@onready var particle_gen: GPUParticles2D = $GPUParticles2D
@onready var particle_material: ParticleProcessMaterial = particle_gen.process_material
@onready var light: PointLight2D = $PointLight2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var mouse_area: Area2D = $PlayerTracker
@onready var popup: MarginContainer = $Popup
@onready var popup_message: MessageBox = $Popup/MessageBox
@onready var animation: AnimationPlayer = $AnimationPlayer

var collected: bool = false:
    set(value):
        collected = value
        if is_node_ready() and collected:
            dispawn()
        
#region Exported variables
@export_group("Presets")
## Boosters add a property, Upgraders increase the boosters strength 
@export var buff_preset: BuffPreset = BuffPreset.CUSTOM:
    set(value):
        buff_preset = value
        apply_to_children()
@export var popup_disabled: bool = false
@export_group("Particle")
@export var particle_amount: int = 8:
    set(value):
        particle_amount = value
        if is_node_ready():
            particle_gen.amount = particle_amount
@export var particle_scale_min: float = 1.0:
    set(value):
        particle_scale_min = value
        if is_node_ready():
            particle_material.scale_min = particle_scale_min
@export var particle_scale_max: float = 1.0:
    set(value):
        particle_scale_max = value
        if is_node_ready():
            particle_material.scale_max = particle_scale_max
@export var particle_color: Color = Color.AQUA:
    set(value):
        particle_color = value
        if is_node_ready():
            particle_material.color = particle_color
@export var particle_texture: Texture2D = null:
    set(value):
        particle_texture = value
        if is_node_ready():
            particle_gen.texture = particle_texture
@export var particle_lifetime: float = 1.0:
    set(value):
        particle_lifetime = value
        if is_node_ready():
            particle_gen.lifetime = particle_lifetime
@export var particle_spread: float = 1.0:
    set(value):
        particle_spread = value
        if is_node_ready():
            particle_material.spread = particle_spread
## X is velocity min, Y is velocity max
@export var particle_speed: Vector2 = Vector2.ZERO:
    set(value):
        particle_speed = value
        if is_node_ready():
            particle_material.initial_velocity_min = particle_speed.x
            particle_material.initial_velocity_max = particle_speed.y
@export var particle_direction: Vector3 = Vector3.ZERO:
    set(value):
        if !value.is_normalized():
            particle_direction = value.normalized()
        else:
            particle_direction = value
        if is_node_ready():
            particle_material.direction = particle_direction
@export var particle_gravity: Vector2 = Vector2.ZERO:
    set(value):
        particle_gravity = value
        if is_node_ready():
            particle_material.gravity = Vector3(particle_gravity.x, particle_gravity.y, 0)
@export var particle_emission_shape: ParticleProcessMaterial.EmissionShape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_POINT:
    set(value):
        particle_emission_shape = value
        if is_node_ready():
            particle_material.emission_shape = particle_emission_shape
@export_subgroup("Particle Shape")
@export_subgroup("Particle Shape/Sphere")
@export var sphere_radius: float = 1:
    set(value):
        sphere_radius = value
        if is_node_ready():
            particle_material.emission_sphere_radius = sphere_radius
@export_subgroup("Particle Shape/Box")
@export var box_extent: Vector3 = Vector3.ONE:
    set(value):
        box_extent = value
        if is_node_ready():
            particle_material.emission_box_extents = box_extent
@export_subgroup("Particle Shape/Ring")
@export var ring_axis: Vector3 = Vector3.ONE:
    set(value):
        ring_axis = value
        if is_node_ready():
            particle_material.emission_ring_axis = ring_axis
@export var ring_height: float = 1:
    set(value):
        ring_height = value
        if is_node_ready():
            particle_material.emission_ring_height = ring_height
@export var ring_radius: float = 1:
    set(value):
        ring_radius = value
        if is_node_ready():
            particle_material.emission_ring_radius = ring_radius
@export var ring_inner_radius: float = 1:
    set(value):
        ring_inner_radius = value
        if is_node_ready():
            particle_material.emission_ring_inner_radius = ring_inner_radius
@export_group("Orb")
@export var orb_color: Color = Color.AQUA:
    set(value):
        orb_color = value
        if is_node_ready():
            light.color = orb_color
@export var size: float = 1.0:
    set(value):
        size = value
        if is_node_ready():
            light.scale = Vector2(size, size)
@export_group("Sprite")
@export var texture: Texture2D = null:
    set(value):
        texture = value
        if is_node_ready():
            sprite.texture = texture
#endregion

func _ready() -> void:
    # if preset is other than custom, it will override params
    # check buff_preset, and set params to their value
#region Buff Presets
    match buff_preset:
        BuffPreset.CUSTOM:
            pass
        BuffPreset.SPEED_UPGRADER:
            particle_gravity = Vector2(5, -5)
            particle_amount = 50
            particle_scale_max = 5
            particle_color = Color("0010ff")
            orb_color = Color("0010ff")
            particle_lifetime = 3
            particle_emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_RING
            ring_inner_radius = 10
            ring_radius = 20
        BuffPreset.SPEED_BOOSTER:
            particle_amount = 50
            particle_scale_max = 5
            particle_color = Color("0010ff")
            orb_color = Color("0010ff")
            particle_lifetime = 3
            particle_emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_RING
            ring_inner_radius = 10
            ring_radius = 20
        BuffPreset.HEALTH_BOOSTER:
            particle_amount = 50
            particle_scale_max = 5
            particle_color = Color("ff0078")
            orb_color = Color("ffffff")
            particle_lifetime = 3
            particle_emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_RING
            ring_inner_radius = 10
            ring_radius = 20
            particle_gravity = Vector2(0, -3)
            size = 0.3
        BuffPreset.HEALTH_UPGRADER:
            particle_amount = 50
            particle_scale_max = 5
            particle_color = Color("ff0078")
            orb_color = Color("ffffff")
            particle_lifetime = 3
            particle_emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_SPHERE_SURFACE
            sphere_radius = 10
            particle_gravity = Vector2(0, -3)
            size = 0.3
        BuffPreset.JUMP_UPGRADER:
            particle_amount = 50
            particle_scale_max = 5
            particle_color = Color("08ff00")
            orb_color = Color("08ff00")
            particle_lifetime = 3
            particle_emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_SPHERE_SURFACE
            sphere_radius = 10
            particle_gravity = Vector2(0, -10)
            animation.play("jump")
        BuffPreset.DASH_UPGRADER:
            particle_amount = 50
            particle_scale_max = 5
            particle_color = Color("020044")
            orb_color = Color("9da8ff")
            particle_lifetime = 3
            particle_emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_RING
            particle_gravity = Vector2(0, -2)
            ring_inner_radius = 10
            ring_radius = 20
            ring_axis = Vector3(1, 10, 1)
        _:
            popup_disabled = true
            push_error("Buff preset ", BuffPreset.get(buff_preset), " is not available")
#endregion

    # apply preset to childrens
    apply_to_children()

func apply_to_children() -> void:
    if !is_node_ready():
        return

    particle_gen.amount = particle_amount
    particle_material.gravity = Vector3(particle_gravity.x, particle_gravity.y, 0)
    particle_material.scale_max = particle_scale_max
    particle_material.scale_min = particle_scale_min
    particle_material.color = particle_color
    particle_gen.texture = particle_texture
    particle_gen.lifetime = particle_lifetime
    particle_material.spread = particle_spread

    # particle_speed
    particle_material.initial_velocity_min = particle_speed.x
    particle_material.initial_velocity_max = particle_speed.y
    # particle_direction
    particle_material.direction = particle_direction

    particle_material.emission_shape = particle_emission_shape
    match particle_emission_shape:
        0: # point
            pass
        1, 2: # sphere and sphere surface
            particle_material.emission_sphere_radius = sphere_radius
        3: # box
            particle_material.emission_box_extents = box_extent
        4, 5: # points and directed points
            # both of this are position texture driven
            pass
        6: # ring
            # imagine the ring like a cylinder
            # the axis is how it is rotated in the scene: 0 0 1 is facing us
            # the height is the length of the cylinder
            # inner radius and radius are explicit
            particle_material.emission_ring_axis = ring_axis
            particle_material.emission_ring_height = ring_height
            particle_material.emission_ring_inner_radius = ring_inner_radius
            particle_material.emission_ring_radius = ring_radius
        _: # invalid
            pass


    light.color = orb_color

    # size is scale the orb to increase size
    light.scale = Vector2(size, size)

    sprite.texture = texture
    
    if popup_disabled:
        mouse_area.input_pickable = false
    
    popup_message.title = buff_title[buff_preset]
    popup_message.content = buff_description[buff_preset]
    
func _on_area_2d_body_entered(body: Node2D) -> void:
    if body is not BasePlayer or collected:
        return
    var player: BasePlayer = body
    if player.player_disabled:
        return
    var id = player.name.to_int()
    var data := Game.Players.get_player(id)
    if data == null and !player.DEBUG:
        push_warning("The player colliding is not in the player list")
        return
    
    data.add_buff(buff_preset)
    
    player.update_buff(data)
    Multi.player_buff_update.rpc(id, str(data))
    Game.player_infos_update.emit(data)
    collected = true

func _on_player_tracker_body_entered(body: Node2D) -> void:
    if body != Game.main_player_instance:
        return
    # FIXME disable collisions instead
    if !popup_disabled or !collected:
        popup.show()

func _on_player_tracker_body_exited(body: Node2D) -> void:
    if body != Game.main_player_instance:
        return
    if !popup_disabled or !collected:
        popup.hide()

func dispawn() -> void:
    animation.play("dispawn")
    particle_gen.amount_ratio = 0

func transition_to_color(_time: int, _new_color: Color) -> void:
    # TODO transition color
    pass
