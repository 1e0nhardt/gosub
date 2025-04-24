class_name Project
extends Resource

@export var uid_string: String = ""
@export var project_name: String = ""
@export var video_url = ""

@export var video_path: String = ""
@export var video_title: String = ""

@export var pipeline_stage := -1
@export var create_time: String = ""
@export var modify_time: String = ""

var dirty: bool = false
var project_folder: String:
    get(): return ProjectManager.PROJECT_FILE_FOLDER.path_join(uid_string) + "/"
var project_file_path: String:
    get(): return ProjectManager.PROJECT_FILE_FOLDER.path_join(uid_string).path_join("project.tres")
var thumbnail_path: String:
    get(): return get_save_basename() + ".png"
var audio_path: String:
    get(): return get_save_basename() + ".wav"
var transcribe_result_path: String:
    get(): return get_save_basename() + ".json"
var output_video_title: String:
    get(): return sanitize_path(video_title)

var subtitle_track: SubtitleTrack = SubtitleTrack.new()


func save() -> void:
    subtitle_track.export_subtitle_file()
    var err := ResourceSaver.save(self, project_file_path)
    if err != OK:
        ProjectManager.send_status_message("Error saving project: " + str(err))
    else:
        modify_time = Util.get_current_timestamp()
        dirty = false
        EventBus.project_saved.emit()
        ProjectManager.send_status_message("Project <%s> saved." % project_name)


func load() -> void:
    EventBus.project_name_changed.emit.call_deferred(project_name)
    EventBus.pipeline_stage_changed.emit.call_deferred(pipeline_stage)

    if not video_path:
        video_path = get_save_basename() + ".mp4"

    EventBus.video_changed.emit.call_deferred(video_path)
    reload_subtitle()


func reload_subtitle() -> void:
    var ass_path := get_save_basename() + ".ass"
    if Util.check_path(ass_path):
        subtitle_track.load_subtitle(ass_path)
    else:
        subtitle_track.clear()


func initialize(uid: String) -> void:
    create_time = Util.get_current_timestamp()
    modify_time = create_time
    uid_string = uid
    Util.ensure_dir(project_folder)
    dirty = true


func set_video_title(title: String, use_as_project_name: bool = false) -> void:
    video_title = title
    dirty = true
    if use_as_project_name:
        project_name = video_title
        EventBus.project_name_changed.emit(video_title)


func get_save_basename() -> String:
    return ProjectSettings.globalize_path(project_folder.path_join(uid_string))


func sanitize_path(path: String) -> String:
    path = path.replace("\\", "")
    path = path.replace("/", "")
    path = path.replace("?", "")
    path = path.replace("*", "")
    path = path.replace(":", "")
    path = path.replace("\"", "")
    path = path.replace("<", "")
    path = path.replace(">", "")
    path = path.replace("|", "")
    return path


func to_pretty() -> Dictionary:
    return {
        "uid_string": uid_string,
        "project_name": project_name,
        "video_url": video_url,
        "video_title": video_title,
        "create_time": create_time,
        "modify_time": modify_time,
    }