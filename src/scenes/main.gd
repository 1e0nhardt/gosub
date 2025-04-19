extends Control

@export var menu_bar_stylebox: StyleBox
@export var bg_stylebox: StyleBox

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
var subtitle_label_state: int = 0

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var center_helper: Control = %CenterHelper
@onready var viewport: TextureRect = %Viewport
@onready var play_button: Button = %PlayButton
@onready var subtitle_button: Button = %SubtitleButton
@onready var progress_slider: HSlider = %ProgressSlider
@onready var time_label: Label = %TimeLabel
@onready var project_name_edit: LineEdit = %ProjectNameEdit
@onready var subtitle_label: Label = %SubtitleLabel
@onready var subtitle_label2: Label = %SubtitleLabel2
@onready var menu_bar: HBoxContainer = %MenuBar
@onready var vsplit_container: VSplitContainer = %VSplitContainer
@onready var file_menu_button: MenuButton = %FileMenuButton
@onready var edit_menu_button: MenuButton = %EditMenuButton
@onready var help_menu_button: MenuButton = %HelpMenuButton


func _ready() -> void:
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

    center_helper.resized.connect(func():
        var new_size = center_helper.size
        viewport.size.y = new_size.y
        viewport.size.x = new_size.y * 16.0 / 9.0
        viewport.position = (new_size - viewport.size) / 2.0
    )

    play_button.toggled.connect(_on_play_button_toggled)
    progress_slider.drag_started.connect(_on_progress_slider_drag_started)
    progress_slider.drag_ended.connect(_on_progress_slider_drag_ended)
    project_name_edit.mouse_entered.connect(func(): mouse_on_project_name_edit = true)
    project_name_edit.mouse_exited.connect(func(): mouse_on_project_name_edit = false)
    project_name_edit.text_submitted.connect(func(new_text):
        var new_name = new_text.replace("*", "")
        ProjectManager.current_project.project_name = new_name
        _on_project_name_changed(new_name)
    )
    subtitle_button.pressed.connect(func():
        subtitle_label_state = (subtitle_label_state + 1) % 3
        var button_text: String
        match subtitle_label_state:
            0:
                button_text = "ALL"
            1:
                button_text = "ZH"
            2:
                button_text = "EN"
        subtitle_button.text = button_text
        update_subtitle_labels_visibility()
    )

    # Menu Buttons
    var file_menu_popup = file_menu_button.get_popup()
    @warning_ignore_start("int_as_enum_without_cast")
    @warning_ignore_start("int_as_enum_without_match")
    file_menu_popup.add_item("Select Project", 0, KEY_MASK_CTRL | KEY_E)
    file_menu_popup.add_item("Save Project", 1, KEY_MASK_CTRL | KEY_S)
    file_menu_popup.add_item("Open project folder", 2)
    file_menu_popup.id_pressed.connect(func(id):
        match id:
            0:
                ProjectManager.show_select_project_popup()
            1:
                ProjectManager.save_project()
            2:
                OS.shell_show_in_file_manager(ProjectSettings.globalize_path(ProjectManager.current_project.project_folder), true)
    )

    var edit_menu_popup = edit_menu_button.get_popup()
    edit_menu_popup.add_item("Settings", 0, KEY_MASK_CTRL | KEY_P)
    edit_menu_popup.id_pressed.connect(func(id):
        match id:
            0:
                ProjectManager.show_settings_popup()
    )

    var help_menu_popup = help_menu_button.get_popup()
    help_menu_popup.add_item("About", 0)
    help_menu_popup.id_pressed.connect(func(id):
        match id:
            0:
                ProjectManager.show_message("About", "This is a test message.")
    )
    @warning_ignore_restore("int_as_enum_without_cast")
    @warning_ignore_restore("int_as_enum_without_match")

    ProjectManager.show_select_project_popup()

    queue_redraw.call_deferred()


func _draw() -> void:
    draw_style_box(menu_bar_stylebox, Rect2(Vector2.ZERO, menu_bar.size))
    draw_style_box(bg_stylebox, Rect2(Vector2(0, menu_bar.size.y), vsplit_container.size))


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
        if mouse_on_project_name_edit:
            project_name_edit.editable = true
            project_name_edit.selecting_enabled = true
        else:
            project_name_edit.editable = false
            project_name_edit.selecting_enabled = false
            if ProjectManager.current_project:
                ProjectManager.current_project.project_name = project_name_edit.text.replace("*", "")


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
    if not is_node_ready():
        await ready

    video.close_video()

    if not FileAccess.file_exists(filepath):
        return

    # Logger.info("Video Path: %s" % filepath)

    video.open_video(filepath)
    audio_stream_player.stream = video.get_audio()
    max_frame = video.get_total_frame_number()
    raw_frame_rate = video.get_frame_rate()
    frame_rate = raw_frame_rate
    progress_slider.max_value = max_frame

    seek_frame(1, true)
    if FileAccess.file_exists(ProjectManager.current_project.thumbnail_path):
        var thumbnail_image = Image.load_from_file(ProjectManager.current_project.thumbnail_path)
        viewport.texture.set_image(thumbnail_image)


func seek_frame(frame_number: int, flush_canvas = false):
    if frame_number < 0 or frame_number >= max_frame:
        Logger.info("Invalid frame number: %s" % frame_number)
        return

    var img = video.seek_frame(frame_number)
    if flush_canvas:
        viewport.texture.set_image(img)
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


func update_subtitle_labels_visibility():
    match subtitle_label_state:
            0:
                subtitle_label.show()
                subtitle_label2.show()
            1:
                subtitle_label.show()
                subtitle_label2.hide()
            2:
                subtitle_label.hide()
                subtitle_label2.show()


func update_subtitles():
    if ProjectManager.current_project and not ProjectManager.current_project.subtitle_track.is_empty():
        ProjectManager.current_project.subtitle_track.update(current_time)
        if ProjectManager.current_project.subtitle_track.current_clip.compare(current_time) == 0:
            update_subtitle_labels_visibility()
            subtitle_label.text = ProjectManager.current_project.subtitle_track.current_clip.first_text
            subtitle_label2.text = ProjectManager.current_project.subtitle_track.current_clip.second_text
        else:
            subtitle_label.hide()
            subtitle_label2.hide()

#region video player events
func _on_play_button_toggled(toggled_on: bool) -> void:
    play(toggled_on)


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


func _on_project_saved() -> void:
    project_name_edit.text = ProjectManager.current_project.project_name
