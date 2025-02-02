class_name DamageNumber
extends Node

enum DamageType {
    NORMAL = 0,
    DAMAGE = 1,
    HEAL = 2
}

const SIZE = Vector2(100, 25)

func display_number(value: int, position: Vector2, type: DamageType = DamageType.NORMAL, is_critical = false) -> void:
    # remove is_critical if value is 0
    if value == 0:
        is_critical = false 
    
    var number: Label = Label.new()
    number.custom_minimum_size = SIZE
    number.size = SIZE
    number.global_position = Vector2(position.x - SIZE.x / 2, position.y - SIZE.y / 2)
    number.text = str(value)
    number.z_index = 5
    number.label_settings = LabelSettings.new()
    
    var color = ""
    match type:
        DamageType.NORMAL:
            color = "#fff" # white
        DamageType.DAMAGE:
            if is_critical:
                color = "#8a2be2" # purple
            else:
                color = "f00" # red
        DamageType.HEAL:
            color = "#0f0" # green
        _: 
            color = "#fff8" # transparent white
    if value == 0:
        color = "#fff8" # no damage -> transparant white
        
    number.label_settings.font_color = color
    number.label_settings.font_size = 18 + (6 if is_critical else 0)
    number.label_settings.outline_color = "#000" # black outline
    number.label_settings.outline_size = 3 + (2 if is_critical else 0)
    
    # center text
    number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER 
    number.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    # add our label to the scene
    add_child.call_deferred(number)
    
    # center our label once it gets its size
    await number.resized
    number.pivot_offset = Vector2(number.size / 2)
    
    # animation
    var tween: Tween = get_tree().create_tween()
    tween.set_parallel(true)
    tween.tween_property(number, "position:y", number.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
    tween.tween_property(number, "position:y", number.position.y, 0.5).set_ease(Tween.EASE_IN).set_delay(0.25)
    tween.tween_property(number, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.5)
    
    await tween.finished
    number.queue_free()
    
    
    
