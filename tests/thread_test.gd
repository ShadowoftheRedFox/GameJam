extends Node

var prefab_list: Dictionary = {}
var sprite_list: Dictionary = {}
var scene_list: Dictionary = {}

var prefabs: Dictionary = {}
var sprites: Dictionary = {}
var scenes: Dictionary = {}

var thread: Thread = Thread.new()

signal resource_loaded(resource, resource_type, load_state, resource_load_state)
signal resource_load_completed()
signal thread_finished(result)

func _ready() -> void:
    thread_finished.connect(_on_ResourceManager_thread_finished)
    setup_resource_lists()

func setup_resource_lists() -> void:
    prefab_list["prefab1"] = "res://prefabs/prefab1.tscn"
    prefab_list["prefab2"] = "res://prefabs/prefab2.tscn"
    sprite_list["sprite1"] = "res://sprites/sprite1.png"
    sprite_list["sprite2"] = "res://sprites/sprite2.png"
    scene_list["scene1"] = "res://scenes/scene1.tscn"
    scene_list["scene2"] = "res://scenes/scene2.tscn"

func load_resources() -> void:
    var thread_data:Dictionary = {}
    thread_data["sprite_list"] = sprite_list.duplicate()
    thread_data["prefab_list"] = prefab_list.duplicate()
    thread_data["scene_list"] = scene_list.duplicate()
    thread.start(load_resources_parallel.bind(thread_data), Thread.PRIORITY_HIGH)

func load_resources_parallel(thread_data:Dictionary) -> void:
    var result:Dictionary = {}
    result["sprites"] = {}
    result["prefabs"] = {}
    result["scenes"] = {}
    var load_sprite_list:Dictionary = thread_data.sprite_list
    var load_prefab_list:Dictionary = thread_data.prefab_list
    var load_scene_list:Dictionary = thread_data.scene_list
    var load_state_total:int = load_sprite_list.size()+load_prefab_list.size()+load_scene_list.size()
    var current_load_state:int = 0
    var sprite_load_state_total:int = load_sprite_list.size()
    var sprite_current_load_state:int = 0
    for sprite in load_sprite_list:
        var resource:Resource = load(load_sprite_list[sprite])
        result["sprites"][sprite] = resource
        current_load_state += 1
        sprite_current_load_state += 1
        var load_state:float = float(current_load_state)/float(load_state_total)
        var resource_load_state:float = float(sprite_current_load_state)/float(sprite_load_state_total)
        resource_loaded.emit(sprite, "Sprite", load_state, resource_load_state)
    var scene_load_state_total:int = load_sprite_list.size()
    var scene_current_load_state:int = 0
    for scene in load_scene_list:
        var resource:Resource = load(load_scene_list[scene])
        result["scenes"][scene] = resource
        current_load_state += 1
        scene_current_load_state += 1
        var load_state:float = float(current_load_state)/float(load_state_total)
        var resource_load_state:float = float(scene_current_load_state)/float(scene_load_state_total)
        resource_loaded.emit(scene, "Scene", load_state, resource_load_state)
    var prefab_load_state_total:int = load_sprite_list.size()
    var prefab_current_load_state:int = 0
    for prefab in load_prefab_list:
        var resource:Resource = load(load_prefab_list[prefab])
        result["prefabs"][prefab] = resource
        current_load_state += 1
        prefab_current_load_state += 1
        var load_state:float = float(current_load_state)/float(load_state_total)
        var resource_load_state:float = float(prefab_current_load_state)/float(prefab_load_state_total)
        resource_loaded.emit(prefab, "Prefab", load_state, resource_load_state)
    thread_finished.emit(result)

func clear_resources() -> void:
    sprites.clear()
    scenes.clear()
    prefabs.clear()

func _on_ResourceManager_thread_finished(result:Dictionary) -> void:
    sprites = result.sprites
    prefabs = result.prefabs
    scenes = result.scenes
    thread.wait_to_finish()
    resource_load_completed.emit()
