@tool
class_name MessageBox
extends MarginContainer

enum Alignment {LEFT = 0, CENTER = 1, RIGHT = 2, FILL = 3}

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
            
@export var title_alignment: Alignment = Alignment.LEFT:
    set(value):
        title_alignment = value
        realign(title_element, title_alignment)
            
@export var content_alignment: Alignment = Alignment.LEFT:
    set(value):
        content_alignment = value
        realign(content_element, content_alignment)
            

@onready var title_element: Label = $MarginContainer/VBoxContainer/Title
@onready var content_element: Label = $MarginContainer/VBoxContainer/Content

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    title_element.text = title
    content_element.text = content
    title_element.size_flags_horizontal = title_alignment
    content_element.size_flags_horizontal = content_alignment
    realign(title_element, title_alignment)
    realign(content_element, content_alignment)
    
    self.queue_redraw()

func realign(node: Label, value: Alignment) -> void:
    if is_node_ready() and node.is_node_ready():
        match  value:
            Alignment.CENTER:
                node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            Alignment.RIGHT:
                node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            Alignment.FILL:
                node.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
            Alignment.LEFT:
                node.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        node.queue_redraw()
