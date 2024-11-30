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

@export_group("Presets")
@export var buff_preset: BuffPreset = BuffPreset.CUSTOM
@export_group("Particle")
@export var particle_color: Color = Color.AQUA
@export var particle_texture: Texture = null
@export var particle_lifetime: float = 1.0
@export var particle_spread: float = 1.0
@export var particle_speed: float = 1.0
@export var particle_direction: Vector2 = Vector2.ZERO
# it's a preset enum under ParticleProcessMaterial, but not in node2d
@export_enum(
    "Point:0", "Sphere:1", "Sphere surface:2", "Box:3", 
    #"Points:4", "Directed points:5", 
    "Ring:6"
) var particle_emission_shape = 0;
@export_subgroup("Particle Shape")
@export_subgroup("Particle Shape/Sphere")
@export var sphere_radius: float = 1
@export_subgroup("Particle Shape/Box")
@export var box_extent: Vector3 = Vector3.ONE
@export_subgroup("Particle Shape/Ring")
@export var ring_axis: Vector3 = Vector3.ONE
@export var ring_height: float = 1
@export var ring_radius: float = 1
@export var ring_inner_radius: float = 1
@export_group("Orb")
@export var orb_color: Color = Color.AQUA
@export var size: float = 1.0

# Called when the node enters the scene tree for the first time.
func _init() -> void:
    # TODO check buff_preset, and set params to their value
    match buff_preset:
        BuffPreset.CUSTOM:
            pass
        _: 
            printerr("Preset no ", buff_preset, " is not available")
    
    # apply param to childrens
    apply_to_children()


func apply_to_children() -> void:
    #particle_color
    #particle_texture
    #particle_lifetime
    #particle_spread
    #particle_speed
    #particle_direction
    #orb_color
    #size
    pass
