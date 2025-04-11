@tool
class_name CustomTabButton
extends Button

@export var main_color: Color = Color.BLACK
@export var focus_stylebox: StyleBox


var selected: bool = false:
    set(value):
        selected = value
        button_pressed = selected
        queue_redraw.call_deferred()


func _ready() -> void:
    add_theme_color_override("font_pressed_color", main_color)
    add_theme_color_override("font_hover_color", main_color)
    add_theme_color_override("font_hover_pressed_color", main_color)

    var empty_stylebox = StyleBoxEmpty.new()
    add_theme_stylebox_override("focus", empty_stylebox)
    add_theme_stylebox_override("pressed", empty_stylebox)
    add_theme_stylebox_override("hover", empty_stylebox)
    add_theme_stylebox_override("normal", empty_stylebox)
    add_theme_stylebox_override("hover_pressed", empty_stylebox)


func _draw() -> void:
    if selected:
        draw_style_box(focus_stylebox, Rect2(Vector2.ZERO, size))
