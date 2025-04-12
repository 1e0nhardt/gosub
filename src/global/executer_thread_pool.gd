extends Node

var executer_thread_queue := []
var executer_thread_mutex: Mutex
var running_task_ids := []
var closing := false


func _ready() -> void:
    executer_thread_mutex = Mutex.new()


func _process(_delta: float) -> void:
    if closing:
        return

    while executer_thread_queue.size() > 0:
        var data_info = executer_thread_queue.pop_front()
        data_info[0].call_deferred(data_info[1])

    for i in range(running_task_ids.size() - 1, -1, -1):
        var task_id = running_task_ids[i]
        if WorkerThreadPool.is_task_completed(task_id):
            WorkerThreadPool.wait_for_task_completion(task_id)
            running_task_ids.remove_at(i)


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        #  Wait for all tasks to complete
        closing = true
        for i in range(running_task_ids.size() - 1, -1, -1):
            var task_id = running_task_ids[i]
            WorkerThreadPool.wait_for_task_completion(task_id)


func request_thread_execution(execute_params: Dictionary, callback: Callable) -> void:
    var task_id = WorkerThreadPool.add_task(executer_thread.bind(execute_params, callback))
    running_task_ids.append(task_id)


func executer_thread(execute_params: Dictionary, callback: Callable) -> void:
    if not execute_params.has("type"):
        Logger.error("Invalid execute request! Missing type!")
        Logger.error("Execute params: %s" % execute_params)
        return

    var err_flag := false
    var result := {}
    Logger.info(execute_params)
    match execute_params["type"]:
        "query_video_title":
            var video_title = Executer.get_video_title(execute_params["url"]).strip_edges()
            result = {
                "succeed": video_title != "",
                "video_title": video_title
            }
        "download_video":
            var video_basename = execute_params["save_basename"] as String
            ProjectManager.current_project.video_path = video_basename + ".mp4"
            err_flag = Executer.download_video(execute_params["url"], video_basename + ".mp4")
            result = {
                "succeed": err_flag,
            }
        "extract_audio":
            err_flag = Executer.extract_audio(execute_params["video_path"], ProjectManager.current_project.get_save_basename() + ".wav")
            result = {
                "succeed": err_flag,
            }
        "transcribe_audio":
            err_flag = Executer.transcribe_audio(execute_params["audio_path"], execute_params["audio_path"].get_basename() + ".json")
            result = {
                "succeed": err_flag,
            }
        "ai_translate":
            DeepSeekApi.json_to_clips(execute_params["json_path"])
            err_flag = true
            result = {
                "succeed": err_flag,
            }
        "transcribe_segment":
            err_flag = Executer.transcribe_segment(execute_params["audio_path"], execute_params["from"], execute_params["to"])
            var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ProjectManager.current_project.project_folder.path_join("temp_segment.json")))
            result = {
                "succeed": err_flag,
                "data": json
            }
        "render_video":
            var ass_path = execute_params["ass_path"]
            var video_title = execute_params["video_title"]
            err_flag = Executer.render_video_with_hard_subtitles(
                ProjectManager.current_project.video_path,
                ass_path,
                ass_path.get_base_dir().path_join("%s.mp4" % video_title),
                execute_params.get("bit_rate", "6M"),
            )
            result = {
                "succeed": err_flag
            }

    executer_thread_mutex.lock()
    executer_thread_queue.append([callback, result])
    executer_thread_mutex.unlock()
