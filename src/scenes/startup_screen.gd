class_name StartupScreen
extends Control

const PROJECT_ITEM_SCENE = preload("res://scenes/ui/project_item.tscn")

@onready var new_button: Button = %NewButton
@onready var projects_container: HFlowContainer = %ProjectsContainer


func _ready() -> void:
    new_button.pressed.connect(_on_new_button_pressed)
    var window = get_window()
    var window_size = Vector2i(160 * 4 + 20 * 3, 360)
    Util.center_main_window(window, window_size)
    window.unresizable = true

    for p in ProjectManager.registered_projects.values():
        var item_instance = PROJECT_ITEM_SCENE.instantiate()
        projects_container.add_child(item_instance)
        item_instance.set_project(p)


func _on_new_button_pressed() -> void:
    ProjectManager.new_project()
    get_tree().change_scene_to_file("res://scenes/main.tscn")
