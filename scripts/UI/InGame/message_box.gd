@tool
class_name MessageBox
extends MarginContainer

enum Alignment {LEFT, CENTER, RIGHT}

@export var title: String = "This is a title.":
    set(value):
        title = value
        if is_node_ready():
            title_element.text = title
            queue_redraw()

@export var content: String = "This is a content.":
    set(value):
        content = value
        if is_node_ready():
            content_element.text = content
            queue_redraw()
            
@export_enum("Left:0","Center:1","Right:2","Fill:3") var title_alignment: int = HORIZONTAL_ALIGNMENT_LEFT:
    set(value):
        title_alignment = value
        if is_node_ready():
            title_element.horizontal_alignment = value
            queue_redraw()            
            
@export_enum("Left:0","Center:1","Right:2","Fill:3") var content_alignment: int = HORIZONTAL_ALIGNMENT_LEFT:
    set(value):
        content_alignment = value
        if is_node_ready():
            content_element.horizontal_alignment = content_alignment
            queue_redraw()
            

@onready var title_element: Label = $MarginContainer/VBoxContainer/Title
@onready var content_element: Label = $MarginContainer/VBoxContainer/Content

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    title_element.text = title
    content_element.text = content
    title_element.size_flags_horizontal = title_alignment
    content_element.size_flags_horizontal = content_alignment
    
    self.queue_redraw()
