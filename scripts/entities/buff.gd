@tool
class_name Buff
extends Node2D

enum BuffPreset {
    CUSTOM = 0,
    SPEED_1 = 1,
    SPEED_2 = 2,
    SPEED_3 = 3,
    HEALTH_1 = 4,
    HEALTH_2 = 5,
    HEALTH_3 = 6,
}

@onready var particle_gen := $GPUParticles2D as GPUParticles2D
@onready var particle_material := particle_gen.get("process_material") as ParticleProcessMaterial
@onready var light := $PointLight2D as PointLight2D
@onready var sprite := $Sprite2D as Sprite2D

@export_group("Presets")
@export var buff_preset: BuffPreset = BuffPreset.CUSTOM:
    get:
        return buff_preset
    set(value):
        buff_preset = value
        apply_to_children()
@export var buff_name: String = "":
    get:
        return buff_name
    set(value):
        buff_name = value
        if self.is_node_ready():
            self.name = buff_name
@export_group("Particle")
@export var particle_amount: int = 8:
    get:
        return particle_amount
    set(value):
        particle_amount = value
        if self.is_node_ready():
            particle_gen.amount = particle_amount
@export var particle_scale_min: float = 1.0:
    get:
        return particle_scale_min
    set(value):
        particle_scale_min = value
        if self.is_node_ready():
            particle_material.scale_min = particle_scale_min
@export var particle_scale_max: float = 1.0:
    get:
        return particle_scale_max
    set(value):
        particle_scale_max = value
        if self.is_node_ready():
            particle_material.scale_max = particle_scale_max
@export var particle_color: Color = Color.AQUA:
    get:
        return particle_color
    set(value):
        particle_color = value
        if self.is_node_ready():
            particle_material.color = particle_color
@export var particle_texture: Texture2D = null:
    get:
        return particle_texture
    set(value):
        particle_texture = value
        if self.is_node_ready():
            particle_gen.texture = particle_texture
@export var particle_lifetime: float = 1.0:
    get:
        return particle_lifetime
    set(value):
        particle_lifetime = value
        if self.is_node_ready():
            particle_gen.lifetime = particle_lifetime
@export var particle_spread: float = 1.0:
    get:
        return particle_spread
    set(value):
        particle_spread = value
        if self.is_node_ready():
            particle_material.spread = particle_spread
@export var particle_speed: float = 1.0:
    get:
        return particle_speed
    set(value):
        particle_speed = value
        # TODO apply_to_children()
@export var particle_direction: Vector2 = Vector2.ZERO:
    get:
        return particle_direction
    set(value):
        particle_direction = value
        # TODO apply_to_children()
@export var particle_gravity: Vector2 = Vector2.ZERO:
    get:
        return particle_gravity
    set(value):
        particle_gravity = value
        if self.is_node_ready():
            particle_material.gravity =  Vector3(particle_gravity.x, particle_gravity.y, 0)
@export var particle_emission_shape: ParticleProcessMaterial.EmissionShape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_POINT:
    get:
        return particle_emission_shape
    set(value):
        particle_emission_shape = value
        if self.is_node_ready():
            particle_material.emission_shape = particle_emission_shape
@export_subgroup("Particle Shape")
@export_subgroup("Particle Shape/Sphere")
@export var sphere_radius: float = 1:
    get:
        return sphere_radius
    set(value):
        sphere_radius = value
        if self.is_node_ready():
            particle_material.emission_sphere_radius = sphere_radius
@export_subgroup("Particle Shape/Box")
@export var box_extent: Vector3 = Vector3.ONE:
    get:
        return box_extent
    set(value):
        box_extent = value
        if self.is_node_ready():
            particle_material.emission_box_extents = box_extent
@export_subgroup("Particle Shape/Ring")
@export var ring_axis: Vector3 = Vector3.ONE:
    get:
        return ring_axis
    set(value):
        ring_axis = value
        if self.is_node_ready():
            particle_material.emission_ring_axis = ring_axis
@export var ring_height: float = 1:
    get:
        return ring_height
    set(value):
        ring_height = value
        if self.is_node_ready():
            particle_material.emission_ring_height = ring_height
@export var ring_radius: float = 1:
    get:
        return ring_radius
    set(value):
        ring_radius = value
        if self.is_node_ready():
            particle_material.emission_ring_radius = ring_radius
@export var ring_inner_radius: float = 1:
    get:
        return ring_inner_radius
    set(value):
        ring_inner_radius = value
        if self.is_node_ready():
            particle_material.emission_ring_inner_radius = ring_inner_radius
@export_group("Orb")
@export var orb_color: Color = Color.AQUA:
    get:
        return orb_color
    set(value):
        orb_color = value
        if self.is_node_ready():
            light.color = orb_color
@export var size: float = 1.0:
    get:
        return size
    set(value):
        size = value
        if self.is_node_ready():
            light.scale = Vector2(size, size)
@export_group("Sprite")
@export var texture: Texture2D = null:
    get:
        return texture
    set(value):
        texture = value
        if self.is_node_ready():
            sprite.texture = texture


func _ready() -> void:
    # if preset is other than custom, it will override params
     # TODO check buff_preset, and set params to their value
    match buff_preset:
        BuffPreset.CUSTOM:
            apply_to_children()
            return
        _:
            printerr("Preset no", buff_preset, " is not available")

    # apply preset to childrens
    apply_to_children()

    # TODO signal when player in area

func apply_to_children() -> void:
    if not self.is_node_ready():
        return

    particle_gen.amount = particle_amount
    particle_material.gravity =  Vector3(particle_gravity.x, particle_gravity.y, 0)
    particle_material.scale_max = particle_scale_max
    particle_material.scale_min = particle_scale_min
    particle_material.color = particle_color
    particle_gen.texture = particle_texture
    particle_gen.lifetime = particle_lifetime
    particle_material.spread = particle_spread

    # TODO change many things in velocity, animated velocity, and maybe accelerations, same for directions
    # particle_speed
    # particle_direction

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

    # TODO what change size? particle? sprite? or scale everything?
    # size is scale the orb
    light.scale = Vector2(size, size)

    sprite.texture = texture


func _on_area_2d_body_entered(body: Node2D) -> void:
    if body == BasePlayer:
        pass # TODO make controller
