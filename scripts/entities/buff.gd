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
@export var buff_name: String = ""
@export_group("Particle")
@export var particle_amount: int = 8
@export var particle_scale_min: float = 1.0
@export var particle_scale_max: float = 1.0
@export var particle_color: Color = Color.AQUA
@export var particle_texture: Texture2D = null
@export var particle_lifetime: float = 1.0
@export var particle_spread: float = 1.0
@export var particle_speed: float = 1.0
@export var particle_direction: Vector2 = Vector2.ZERO
@export var particle_gravity: float = 0
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
@export var texture: Texture2D = null

# Called when the node enters the scene tree for the first time.
func _init() -> void:
    # TODO check buff_preset, and set params to their value
    match buff_preset:
        BuffPreset.CUSTOM:
            pass
        _: 
            printerr("Preset no ", buff_preset, " is not available")

func _ready() -> void:
    # apply param to childrens
    apply_to_children()


func apply_to_children() -> void:
    var particle_gen := $GPUParticles2D as GPUParticles2D
    var particle_material := particle_gen.get("process_material") as ParticleProcessMaterial 
    var light := $PointLight2D as PointLight2D
    var sprite := $Sprite2D as Sprite2D
    
    particle_material.gravity =  Vector3(0, particle_gravity, 0)
    particle_gen.amount = particle_amount
    particle_material.scale_max = particle_scale_max
    particle_material.scale_min = particle_scale_min
    particle_material.color = particle_color
    particle_gen.texture = particle_texture
    particle_gen.lifetime = particle_lifetime
    particle_material.spread = particle_spread
    
    # TODO change many things in velocity, animated velocity, and maybe accelerations, same for directions
    # particle_speed
    # particle_direction
    
    particle_material.emission_shape = particle_emission_shape as ParticleProcessMaterial.EmissionShape
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
    # size
    
    sprite.texture = texture
