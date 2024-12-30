class_name MessageBox
extends MarginContainer

@export var title: String = "This is a title.":
    set(value):
        title = value
        if is_node_ready():
            title_element.text = title
            
@export var title_alignment: SizeFlags = Control.SIZE_SHRINK_BEGIN:
    set(value):
        title_alignment = value
        if is_node_ready():
            title_element.size_flags_horizontal = title_alignment
            
@export var content: String = "This is a content.":
    set(value):
        content = value
        if is_node_ready():
            content_element.text = content
            
@export var content_alignment: SizeFlags = Control.SIZE_SHRINK_BEGIN:
    set(value):
        content_alignment = value
        if is_node_ready():
            content_element.size_flags_horizontal = content_alignment
            

@onready var title_element: Label = $MarginContainer/VBoxContainer/Title
@onready var content_element: Label = $MarginContainer/VBoxContainer/Content

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    title_element.text = title
    content_element.text = content
    title_element.size_flags_horizontal = title_alignment
    content_element.size_flags_horizontal = content_alignment
    
    #title_element.queue_redraw()
    #content_element.queue_redraw()
    self.queue_redraw()
