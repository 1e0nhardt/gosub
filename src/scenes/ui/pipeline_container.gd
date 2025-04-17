class_name PipelineContainer
extends VBoxContainer

@onready var url_edit: LineEdit = %UrlEdit
@onready var download_button: Button = %DownloadButton
@onready var load_button: Button = %LoadButton
@onready var render: Button = %Render
@onready var progress_indicator: ProgressIndicator = %ProgressIndicator
@onready var continue_button: Button = %ContinueButton
@onready var reasr_button: Button = %ReasrButton
@onready var retry_button: Button = %RetryButton


func _ready() -> void:
    EventBus.project_loaded.connect(func(): url_edit.text = ProjectManager.current_project.video_url)
    EventBus.pipeline_stage_changed.connect(func(stage): progress_indicator.stage = stage)
    EventBus.ai_translate_finished.connect(_ai_translate_callback)
    download_button.pressed.connect(_start_pipeline)
    load_button.pressed.connect(_load_local_video)
    continue_button.pressed.connect(func():
        set_stage(4)
        _render_video()
    )
    reasr_button.pressed.connect(_extract_audio_callback.bind({"succeed": true}))
    reasr_button.pressed.connect(EventBus.pipeline_started.emit)
    retry_button.pressed.connect(_transcribe_audio_callback.bind({"succeed": true}))
    retry_button.pressed.connect(EventBus.pipeline_started.emit)
    # render.pressed.connect(_render_video)


func set_stage(n: int) -> void:
    progress_indicator.stage = n


func _load_local_video() -> void:
    set_stage(-1)
    ProjectManager.load_video(
        func(file_path: String):
            ProjectManager.current_project.video_path = file_path
            ProjectManager.current_project.video_title = file_path.get_file().get_basename()
            url_edit.text = file_path
            _download_video_callback({ "succeed": true })
    )


func _start_pipeline() -> void:
    var video_url = url_edit.text.strip_edges()
    if not video_url.begins_with("http"):
        return

    Logger.info("Start pipeline...")
    EventBus.pipeline_started.emit()
    set_stage(-1)
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

    EventBus.video_changed.emit(ProjectManager.current_project.video_path)

    Logger.info("Extracting audio...")
    ExecuterThreadPool.request_thread_execution(
        {
            "type": "extract_audio",
            "video_path": ProjectManager.current_project.video_path,
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

    DeepSeekApi.json_to_clips(ProjectManager.current_project.get_save_basename() + ".json")


func _ai_translate_callback() -> void:
    set_stage(3)
    ProjectManager.current_project.reload_subtitle()
    Logger.info("Translate done!")


func _render_video() -> void:
    if not Util.check_path(ProjectManager.current_project.video_path):
        return

    if not Util.check_path(ProjectManager.current_project.get_save_basename() + ".ass"):
        return

    ExecuterThreadPool.request_thread_execution(
        {
            "type": "render_video",
            "ass_path": ProjectManager.current_project.get_save_basename() + ".ass",
            "video_title": ProjectManager.current_project.output_video_title,
            "bit_rate": ProjectManager.get_setting_value("/video/render/bit_rate"),
        },
        func(response):
            var err_flag = response["succeed"]
            if not err_flag:
                Logger.warn("Render video failed!")
                return

            set_stage(5)
            EventBus.pipeline_finished.emit()
    )
