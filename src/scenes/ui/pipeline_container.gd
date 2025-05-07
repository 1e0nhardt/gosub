class_name PipelineContainer
extends VBoxContainer

@onready var url_edit: LineEdit = %UrlEdit
@onready var download_button: Button = %DownloadButton
@onready var load_button: Button = %LoadButton
@onready var continue_button: Button = %ContinueButton
@onready var vsteps: VSteps = $VSteps


func _ready() -> void:
    EventBus.project_loaded.connect(func(): url_edit.text = ProjectManager.current_project.video_url)
    EventBus.pipeline_stage_changed.connect(
        func(stage):
            set_stage(stage)
            match stage:
                1:
                    _start_pipeline()
                2:
                    _download_video_callback()
                3:
                    _extract_audio_callback()
                4:
                    _transcribe_audio_callback()
                5:
                    _ai_translate_callback()

    )
    EventBus.ai_translate_finished.connect(_ai_translate_callback)
    download_button.pressed.connect(_start_pipeline)
    load_button.pressed.connect(_load_local_video)
    continue_button.pressed.connect(func():
        EventBus.pipeline_started.emit()
        set_stage(6)
        _on_render_video()
    )

    continue_button.disabled = true


func set_stage(n: int) -> void:
    vsteps.current = n
    ProjectManager.current_project.pipeline_stage = n
    if n == 5:
        continue_button.disabled = false
    else:
        continue_button.disabled = true


func _load_local_video() -> void:
    ProjectManager.load_video(
        func(file_path: String):
            ProjectManager.current_project.video_path = file_path
            ProjectManager.current_project.video_title = file_path.get_file().get_basename()
            url_edit.text = file_path
            set_stage(1)
            _download_video_callback()
    )


func _start_pipeline() -> void:
    var video_url = url_edit.text.strip_edges()
    if not video_url.begins_with("http"):
        return

    ProjectManager.send_status_message("Start pipeline...")
    EventBus.pipeline_started.emit()
    set_stage(1)
    ProjectManager.set_video_url(video_url)
    TaskThreadPool.add_task(StatedTask.new(_get_video_title.bind(video_url), _get_video_title_callback))


# 注意：连续使用 bind 绑定参数时，参数绑定的顺序是颠倒的(从右到左)。
# 所以: task 的第一个参数得是 state。后面的参数需要和绑定顺序一致 task 的参数。
# 例如:
# ```
# func foo(a, b, c):
#    print("%s %s : %s" % [a, b, c])
#
# var f = foo.bind("bar").bind("hello", "world")
# f.call() # -> hello world : bar
# ```
func _get_video_title(state: Dictionary, video_url: String) -> void:
    var result = Executer.get_video_title(video_url)
    result = result.strip_edges().split("\n")[-1]
    Logger.debug(result)
    state.merge({
        "succeed": true,
        "video_title": result,
    })


func _get_video_title_callback(state: Dictionary) -> void:
    var err_flag = state["succeed"]
    if not err_flag:
        Logger.warn("Get video title failed!")
        return

    var video_title = state["video_title"]
    ProjectManager.set_video_title(video_title)
    ProjectManager.send_status_message("Downloading video...")
    if FileAccess.file_exists(ProjectManager.current_project.get_save_basename() + ".mp4"):
        _extract_audio_callback()
        return

    var result = Executer.download_video_execute_prepare(
        ProjectManager.current_project.video_url,
        ProjectManager.current_project.get_save_basename() + ".mp4"
    )
    var run_yt_dlp_task = RunProgramTask.new(result[0], result[1], _download_video_callback)
    TaskThreadPool.run_program(run_yt_dlp_task)


func _download_video_callback() -> void:
    set_stage(2)
    if FileAccess.file_exists(ProjectManager.current_project.audio_path):
        _extract_audio_callback()
        return

    EventBus.video_changed.emit(ProjectManager.current_project.video_path)
    ProjectManager.send_status_message("Extracting audio...")
    var result = Executer.extract_audio_execute_prepare(
        ProjectManager.current_project.video_path,
        ProjectManager.current_project.audio_path
    )
    var run_ffmpeg_task = RunProgramTask.new(result[0], result[1], _extract_audio_callback)
    TaskThreadPool.run_program(run_ffmpeg_task)


func _extract_audio_callback() -> void:
    set_stage(3)
    ProjectManager.send_status_message("Transcribing audio...")
    if FileAccess.file_exists(ProjectManager.current_project.transcribe_result_path):
        _transcribe_audio_callback()
        return

    var result = Executer.transcribe_audio_execute_prepare(
        ProjectManager.current_project.audio_path,
        ProjectManager.current_project.transcribe_result_path
    )
    var run_whisper_task = RunProgramTask.new(result[0], result[1], _transcribe_audio_callback)
    TaskThreadPool.run_program(run_whisper_task)


func _transcribe_audio_callback() -> void:
    set_stage(4)
    ProjectManager.send_status_message("Translating start...")
    DeepSeekApi.json_to_clips(ProjectManager.current_project.transcribe_result_path)


func _ai_translate_callback() -> void:
    set_stage(5)
    ProjectManager.current_project.reload_subtitle()
    Logger.info("Translate done!")


func _on_render_video() -> void:
    if not Util.check_path(ProjectManager.current_project.video_path):
        return

    if not Util.check_path(ProjectManager.current_project.get_save_basename() + ".ass"):
        return

    var ass_path = ProjectManager.current_project.get_save_basename() + ".ass"
    var video_title = ProjectManager.current_project.output_video_title
    var result = Executer.render_video_with_hard_subtitles_execute_prepare(
        ProjectManager.current_project.video_path,
        ass_path,
        ass_path.get_base_dir().path_join("%s.mp4" % video_title),
        ProjectManager.get_setting_value("/video/render/bit_rate")
    )
    var run_ffmpeg_task = RunProgramTask.new(result[0], result[1], _render_video_callback)
    TaskThreadPool.run_program(run_ffmpeg_task)


func _render_video_callback() -> void:
    set_stage(7)
    EventBus.pipeline_finished.emit()