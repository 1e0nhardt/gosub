class_name ThemeGenerator
extends Control


func _ready() -> void:
    generate_theme()


func generate_theme() -> void:
    ThemeHelper.generate_theme("blue")
    Logger.info("Theme generated")