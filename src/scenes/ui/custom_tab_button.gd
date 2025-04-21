@tool
class_name CustomTabButton
extends Button

var selected_stylebox: StyleBox


var selected: bool = false:
    set(value):
        selected = value
        button_pressed = selected
        queue_redraw.call_deferred()


func _ready() -> void:
    selected_stylebox = get_theme_stylebox("selected", "TabButton")
    theme_type_variation = "TabButton"


func _draw() -> void:
    if selected:
        draw_style_box(selected_stylebox, Rect2(Vector2.ZERO, size))
