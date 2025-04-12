extends Control

var is_playing: bool = false
var max_frame: int = 0
var raw_frame_rate: float = 0
var frame_rate: float = 0
var current_frame: int = 0:
    set(value):
        current_frame = value
        time_label.text = "%s/%s" % [
            Util.time_float2str(current_frame / raw_frame_rate),
            Util.time_float2str(max_frame / raw_frame_rate),
        ]
var current_time: float = 0:
    get: return current_frame / raw_frame_rate
var elapsed_time: float = 0
var frame_time: float:
    get: return 1.0 / frame_rate
var dragging = false
var video: Video = Video.new()
var mouse_on_project_name_edit: bool = false

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var viewport: TextureRect = %Viewport
@onready var play_button: Button = %PlayButton
@onready var progress_slider: HSlider = %ProgressSlider
@onready var time_label: Label = %TimeLabel
@onready var project_name_edit: LineEdit = %ProjectNameEdit
@onready var subtitle_label: Label = %SubtitleLabel
@onready var subtitle_label2: Label = %SubtitleLabel2


func _ready() -> void:
    ProjectManager.load_project()

    # 获取主窗口
    var window = get_window()
    var window_size = Vector2i(1920, 1080)
    Util.center_main_window(window, window_size)
    window.unresizable = false

    EventBus.project_name_changed.connect(_on_project_name_changed)
    EventBus.project_saved.connect(_on_project_saved)

    EventBus.video_changed.connect(open_video)
    EventBus.video_paused.connect(func(b): play(b))
    EventBus.jump_to_here_requested.connect(func(time):
        seek_time(time, true)
        update_subtitles()
    )

    EventBus.ai_translate_progress_updated.connect(func(progress):
        Logger.info("AI translate progress: %.2f" % progress)
    )
    EventBus.ai_translate_finished.connect(func():
        Logger.info("AI translate finished")
    )

    play_button.pressed.connect(_on_play_button_pressed)
    progress_slider.drag_started.connect(_on_progress_slider_drag_started)
    progress_slider.drag_ended.connect(_on_progress_slider_drag_ended)
    project_name_edit.mouse_entered.connect(func(): mouse_on_project_name_edit = true)
    project_name_edit.mouse_exited.connect(func(): mouse_on_project_name_edit = false)

    # ProjectManager.show_blocker()
    # await get_tree().create_timer(2).timeout
    # ProjectManager.hide_blocker()
    ProjectManager.show_message("Welcome to Gosub!", "This is a easy to use video translate tool.")


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
        if mouse_on_project_name_edit:
            project_name_edit.editable = true
            project_name_edit.selecting_enabled = true
        else:
            project_name_edit.editable = false
            project_name_edit.selecting_enabled = false
            ProjectManager.current_project.project_name = project_name_edit.text

    if event is InputEventKey:
        if event.is_pressed() and event.keycode == KEY_S and event.ctrl_pressed:
            ProjectManager.save_project()


func _process(delta) -> void:
    if is_playing:
        elapsed_time += delta
        if elapsed_time < frame_time:
            return

        elapsed_time -= frame_time
        if !dragging:
            current_frame += 1

            if current_frame >= max_frame:
                is_playing = !is_playing
                video.seek_frame(1)
                current_frame = 1
                audio_stream_player.stream_paused = true
            else:
                viewport.texture.set_image(video.next_frame())

            progress_slider.value = current_frame

        update_subtitles()


func open_video(filepath: String):
    if not filepath:
        return

    video.close_video()

    Logger.info("Video Path: %s" % filepath)

    video.open_video(filepath)
    audio_stream_player.stream = video.get_audio()
    max_frame = video.get_total_frame_number()
    raw_frame_rate = video.get_frame_rate()
    frame_rate = raw_frame_rate
    progress_slider.max_value = max_frame

    seek_frame(1)
    var thumbnail_image = Image.load_from_file(ProjectManager.current_project.thumbnail_path)
    viewport.texture.set_image(thumbnail_image)


func seek_frame(frame_number: int, flush_canvas = false):
    if flush_canvas:
        video.seek_frame(frame_number - 1)
        if frame_number <= max_frame:
            viewport.texture.set_image(video.next_frame())
    else:
        video.seek_frame(frame_number)
    current_frame = frame_number
    audio_stream_player.play(current_time)
    audio_stream_player.stream_paused = !is_playing
    progress_slider.set_value_no_signal(current_frame)


func seek_time(time: float, flush_canvas = false):
    seek_frame(ceili(time * raw_frame_rate), flush_canvas)


func play(flag: bool):
    is_playing = flag
    if is_playing:
        audio_stream_player.play(current_frame * frame_time)

    audio_stream_player.stream_paused = !is_playing


func update_subtitles():
    if ProjectManager.current_project and not ProjectManager.current_project.subtitle_track.is_empty():
        ProjectManager.current_project.subtitle_track.update(current_time)
        if ProjectManager.current_project.subtitle_track.current_clip.compare(current_time) == 0:
            subtitle_label.show()
            subtitle_label2.show()
            subtitle_label.text = ProjectManager.current_project.subtitle_track.current_clip.first_text
            subtitle_label2.text = ProjectManager.current_project.subtitle_track.current_clip.second_text
        else:
            subtitle_label.hide()
            subtitle_label2.hide()

#region video player events
func _on_play_button_pressed() -> void:
    Logger.info("Play button pressed")
    play(!is_playing)


func _on_progress_slider_drag_ended(_value_changed):
    dragging = false
    seek_frame(int(progress_slider.value))


func _on_progress_slider_drag_started():
    dragging = true
    audio_stream_player.stream_paused = true
#endregion


func _on_project_name_changed(project_name: String) -> void:
    Logger.info("Project name changed: %s" % project_name)
    var suffix = "*" if ProjectManager.current_project.dirty else ""
    project_name_edit.text = project_name + suffix


func _on_project_saved(project_name: String) -> void:
    project_name_edit.text = project_name
