class_name ProjectItem
extends MarginContainer

signal project_selected(p: Project)
signal project_clicked(i: int, control_pressed: bool)

@export var clicked_stylebox: StyleBox

var project: Project
var index: int
var clicked: bool = false:
    set(value):
        clicked = value
        queue_redraw()

@onready var panel_container: PanelContainer = %PanelContainer
@onready var name_label: Label = %NameLabel


func _ready() -> void:
    panel_container.gui_input.connect(_on_panel_container_gui_input)


func _draw() -> void:
    if clicked:
        draw_style_box(clicked_stylebox, Rect2(Vector2.ZERO, size))


func _on_panel_container_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
            if event.double_click:
                project_selected.emit(project)
            else:
                project_clicked.emit(index, event.ctrl_pressed)


func set_project(p_project: Project, ind: int) -> void:
    project = p_project
    index = ind
    name_label.text = project.project_name
    update_thumbnail()


func update_thumbnail() -> void:
    if not FileAccess.file_exists(project.thumbnail_path):
        return

    var texture_stylebox := StyleBoxTexture.new()
    var thumbnail_image = Image.load_from_file(project.thumbnail_path)
    texture_stylebox.texture = ImageTexture.create_from_image(thumbnail_image)
    panel_container.add_theme_stylebox_override("panel", texture_stylebox)
