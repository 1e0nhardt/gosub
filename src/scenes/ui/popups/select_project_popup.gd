class_name SelectProjectPopup
extends PopupManager.PopupControl

const PROJECT_ITEM_SCENE = preload("res://scenes/ui/project_item.tscn")

@onready var new_button: Button = %NewButton
@onready var delete_button: Button = %DeleteButton
@onready var projects_container: HFlowContainer = %ProjectsContainer

var selected_project_index := []


func _ready() -> void:
    new_button.pressed.connect(_on_new_button_pressed)
    delete_button.pressed.connect(_on_delete_button_pressed)


func _update_projects() -> void:
    for child in projects_container.get_children():
        child.queue_free()

    var i = 0
    for p in ProjectManager.registered_projects.values():
        var item_instance = PROJECT_ITEM_SCENE.instantiate()
        projects_container.add_child(item_instance)
        item_instance.set_project(p, i)
        item_instance.project_selected.connect(open_project)
        item_instance.project_clicked.connect(_on_project_clicked)
        i += 1


func open_project(project: Project) -> void:
    ProjectManager.current_project = project
    ProjectManager.load_project()
    close_popup()


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    ProjectManager.show_blocker()
    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)

    if is_node_ready():
        _update_projects()


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)
    ProjectManager.hide_blocker()


func _on_new_button_pressed() -> void:
    ProjectManager.new_project()
    ProjectManager.load_project()
    close_popup()


func _on_delete_button_pressed() -> void:
    for i in selected_project_index:
        ProjectManager.delete_project(projects_container.get_child(i).project)

    selected_project_index.clear()
    _update_projects()


func _on_project_clicked(index: int, ctrl_pressed: bool) -> void:
    if not selected_project_index.has(index):
        if not ctrl_pressed:
            selected_project_index.clear()
        selected_project_index.append(index)

    for child in projects_container.get_children():
        child.clicked = child.index in selected_project_index
