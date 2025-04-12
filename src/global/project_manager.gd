extends Node

const PROJECT_FILE_FOLDER = "user://projects/"
const INFO_POPUP_SCENE = preload("res://scenes/ui/popups/info_popup.tscn")
const REASR_POPUP_SCENE = preload("res://scenes/ui/popups/reasr_popup.tscn")

var current_project: Project = null
var registered_projects: Dictionary[String, Project] = {}

var _info_popup: InfoPopup = null
var _reasr_popup: ReasrPopup = null
var _controls_blocker: PopupManager.PopupControl = null


func _init() -> void:
    Util.ensure_dir(PROJECT_FILE_FOLDER)
    register_projects()


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_project()
    elif what == NOTIFICATION_PREDELETE:
        # if is_instance_valid(_file_dialog):
        #     _file_dialog.queue_free()
        # if is_instance_valid(_info_popup):
        #     _info_popup.queue_free()
        if is_instance_valid(_controls_blocker):
            _controls_blocker.queue_free()

#region Project Management
func new_project() -> void:
    var l_new_project := Project.new()

    var uid := ResourceUID.create_id()
    # uid://uid_string
    var uid_string := ResourceUID.id_to_text(uid).right(-6)
    var full_path = PROJECT_FILE_FOLDER.path_join(uid_string + ".tres")
    ResourceUID.add_id(uid, full_path)

    l_new_project.initialize(uid_string)
    l_new_project.project_name = uid_string
    current_project = l_new_project


func save_project() -> void:
    if current_project:
        Util.ensure_dir(current_project.project_folder)
        current_project.save()
    else:
        Logger.info("No project to save.")


func load_project_from_file(path: String) -> void:
    if not FileAccess.file_exists(path):
        Logger.info("Project file does not exist: " + path)
        return

    current_project = load(path) as Project
    current_project.load()

    if not current_project:
        Logger.info("This is not a valid project file: " + path)


func load_project() -> void:
    if current_project:
        current_project.load()
    else:
        Logger.warn("Invalid project.")


func register_projects() -> void:
    var dir = DirAccess.open(PROJECT_FILE_FOLDER)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                var resource_uid_string = file_name
                var resource_uid := ResourceUID.text_to_id("uid://" + resource_uid_string)
                var full_path = PROJECT_FILE_FOLDER.path_join(file_name).path_join("project.tres")

                # 清理无效的项目
                if not FileAccess.file_exists(full_path):
                    Logger.info("Project file does not exist: " + full_path)
                    Util.delete_folder_recursive(full_path.get_base_dir())
                    file_name = dir.get_next()
                    continue

                if ResourceUID.has_id(resource_uid):
                    ResourceUID.set_id(resource_uid, full_path)
                else:
                    ResourceUID.add_id(resource_uid, full_path)
                registered_projects[resource_uid_string] = load(full_path) as Project
            file_name = dir.get_next()
    else:
        Logger.info("An error occurred when trying to access the dir_path.")

    Logger.info(registered_projects)
#endregion Project Management


func get_info_popup() -> InfoPopup:
    if not _info_popup:
        _info_popup = INFO_POPUP_SCENE.instantiate()

    _info_popup.clear()
    return _info_popup


func show_info_popup(popup: InfoPopup, popup_size: Vector2) -> void:
    popup.size = popup_size
    popup.popup_anchored(Vector2(0.5, 0.5), PopupManager.Direction.OMNI, true)


func show_message(title: String, content: String, popup_size: Vector2 = Vector2(480, 160)) -> void:
    var message := get_info_popup()
    message.title = title
    message.content = content
    # message.add_button("OK", welcome_message.close_popup)
    show_info_popup(message, popup_size)


func get_reasr_popup() -> ReasrPopup:
    if not _reasr_popup:
        _reasr_popup = REASR_POPUP_SCENE.instantiate()

    return _reasr_popup


func show_reasr_popup(popup: ReasrPopup, popup_size: Vector2) -> void:
    popup.size = popup_size
    popup.popup_anchored(Vector2(0.5, 0.5), PopupManager.Direction.OMNI, true)


func show_asr_edit(data: Dictionary) -> void:
    var reasr_popup := get_reasr_popup()
    reasr_popup.json_data = data
    show_reasr_popup(reasr_popup, Vector2(640, 480))


func show_blocker() -> void:
    if not _controls_blocker:
        _controls_blocker = PopupManager.PopupControl.new()

    _controls_blocker.size = get_window().size
    PopupManager.show_popup(_controls_blocker, Vector2.ZERO, PopupManager.Direction.BOTTOM_RIGHT)


func hide_blocker() -> void:
    if not _controls_blocker:
        return

    PopupManager.hide_popup(_controls_blocker)


func set_video_url(url: String) -> void:
    if current_project:
        current_project.video_url = url
        current_project.dirty = true
    else:
        Logger.info("No project to save.")


func set_video_title(title: String) -> void:
    if current_project:
        current_project.set_video_title(title, true)
    else:
        Logger.info("No project to save.")