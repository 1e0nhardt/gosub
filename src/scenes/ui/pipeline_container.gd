class_name PipelineContainer
extends VBoxContainer

@onready var url_edit: LineEdit = %UrlEdit
@onready var start_button: Button = %StartButton
@onready var render: Button = %Render
@onready var progress_indicator: ProgressIndicator = %ProgressIndicator


func _ready() -> void:
    EventBus.pipeline_stage_changed.connect(func(stage): progress_indicator.stage = stage)
    EventBus.ai_translate_finished.connect(_ai_translate_callback)
    start_button.pressed.connect(_start_pipeline)
    # url_edit.text = "https://www.youtube.com/watch?v=nICWuof91iY"
    url_edit.text = "https://www.youtube.com/watch?v=FR618z5xEiM"


func set_stage(n: int) -> void:
    progress_indicator.stage = n


func _start_pipeline() -> void:
    var video_url = url_edit.text
    if video_url == "":
        return

    Logger.info("Start pipeline...")
    ProjectManager.set_video_url(video_url)

    ExecuterThreadPool.request_thread_execution(
        {
            "type": "query_video_title",
            "url": video_url,
        },
        _get_video_title_callback
    )


func _get_video_title_callback(response: Dictionary) -> void:
    var err_flag = response["succeed"]
    if not err_flag:
        Logger.warn("Get video title failed!")
        return

    var video_title = response["video_title"]
    ProjectManager.set_video_title(video_title)

    Logger.info("Video title: %s" % video_title)

    Logger.info("Downloading video...")

    ExecuterThreadPool.request_thread_execution(
        {
            "type": "download_video",
            "url": ProjectManager.current_project.video_url,
            "save_basename": ProjectManager.current_project.get_save_basename(),
        },
        _download_video_callback
    )


func _download_video_callback(response: Dictionary) -> void:
    var err_flag = response["succeed"]
    if not err_flag:
        Logger.warn("Download video failed!")
        return

    set_stage(0)
    EventBus.video_changed.emit(ProjectManager.current_project.get_save_basename() + ".mp4")

    Logger.info("Extracting audio...")
    ExecuterThreadPool.request_thread_execution(
        {
            "type": "extract_audio",
            "video_path": ProjectManager.current_project.get_save_basename() + ".mp4",
        },
        _extract_audio_callback
    )


func _extract_audio_callback(response: Dictionary) -> void:
    var err_flag = response["succeed"]
    if not err_flag:
        Logger.warn("Extract audio failed!")
        return

    set_stage(1)

    Logger.info("Transcribing audio...")
    ExecuterThreadPool.request_thread_execution(
        {
            "type": "transcribe_audio",
            "audio_path": ProjectManager.current_project.get_save_basename() + ".wav",
        },
        _transcribe_audio_callback
    )


func _transcribe_audio_callback(response: Dictionary) -> void:
    var err_flag = response["succeed"]
    if not err_flag:
        Logger.warn("Transcribe audio failed!")
        return

    set_stage(2)

    # ExecuterThreadPool.request_thread_execution.call_deferred(
    #     {
    #         "type": "ai_translate",
    #         "json_path": ProjectManager.current_project.get_save_basename() + ".json",
    #     },
    #     _ai_translate_callback
    # )
    DeepSeekApi.json_to_clips(ProjectManager.current_project.get_save_basename() + ".json")


func _ai_translate_callback() -> void:
    set_stage(3)

    Logger.info("Translate done!")
