@tool
class_name CommonButton
extends Button

enum Type {
    PRIMARY, DEFAULT, TEXT, LINK
}

@export var type: Type = Type.DEFAULT:
    set(value):
        type = value
        theme_type_variation = _get_theme_type_variation_name()


func _ready():
    theme_type_variation = _get_theme_type_variation_name()


func _get_theme_type_variation_name() -> String:
    match type:
        Type.PRIMARY:
            return "PrimaryButton"
        Type.DEFAULT:
            return "DefaultButton"
        Type.TEXT:
            return "TextButton"
        Type.LINK:
            return "LinkTextButton"
        _:
            return ""