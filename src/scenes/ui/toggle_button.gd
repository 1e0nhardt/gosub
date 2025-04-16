@tool
class_name ToggleButton
extends Button

@export var on_icon: Texture2D
@export var off_icon: Texture2D


func _ready():
    toggled.connect(toggle)
    toggle_mode = true
    button_pressed = false
    update_icon()


func update_icon():
    icon = on_icon if button_pressed else off_icon


func toggle(flag: bool) -> void:
    button_pressed = flag
    update_icon()