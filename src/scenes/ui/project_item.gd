class_name ProjectItem
extends MarginContainer

var project: Project

@onready var panel_container: PanelContainer = %PanelContainer
@onready var name_label: Label = %NameLabel


func _ready() -> void:
    panel_container.gui_input.connect(_on_panel_container_gui_input)


func _on_panel_container_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
            open_project()


func open_project() -> void:
    ProjectManager.current_project = project
    # TODO open main scene
    get_tree().change_scene_to_file("res://scenes/main.tscn")


func set_project(p_project: Project) -> void:
    project = p_project
    name_label.text = project.project_name
    update_thumbnail()


func update_thumbnail() -> void:
    if not project.thumbnail_path:
        return

    var texture_stylebox := StyleBoxTexture.new()
    var thumbnail_image = Image.load_from_file(project.thumbnail_path)
    texture_stylebox.texture = ImageTexture.create_from_image(thumbnail_image)
    panel_container.add_theme_stylebox_override("panel", texture_stylebox)
