extends Node

const PROJECT_FILE_FOLDER = "user://projects/"

var current_project: Project = null
var registered_projects: Dictionary[String, Project] = {}


func _ready() -> void:
    Util.ensure_dir(PROJECT_FILE_FOLDER)
    register_projects()


# func init_project() -> void:
#     var temp_project_filepath = PROJECT_FILE_FOLDER.path_join("temp").path_join("project.tres")
#     if FileAccess.file_exists(temp_project_filepath):
#         var temp_project := load(temp_project_filepath) as Project
#         temp_project.load()
#         current_project = temp_project
#         return

#     var l_new_project := Project.new()
#     l_new_project.initialize("temp")
#     l_new_project.project_name = "temp"
#     current_project = l_new_project


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