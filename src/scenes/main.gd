extends Control

var dragging = false
var video: Video = Video.new()
var mouse_on_project_name_edit: bool = false
var subtitle_label_state: int = 0

# theme_cache
var menu_bar_stylebox: StyleBox
var bg_stylebox: StyleBox

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var video_canvas: TextureRect = %VideoCanvas
@onready var video_viewport: SubViewport = %VideoViewport
@onready var play_button: Button = %PlayButton
@onready var render_test_button: Button = %RenderButton
@onready var subtitle_button: Button = %SubtitleButton
@onready var time_label: Label = %TimeLabel
@onready var project_name_edit: LineEdit = %ProjectNameEdit
@onready var subtitle_label: Label = %SubtitleLabel
@onready var subtitle_label2: Label = %SubtitleLabel2
@onready var menu_bar: HBoxContainer = %MenuBar
@onready var hsplit_container: HSplitContainer = %HSplitContainer
@onready var file_menu_button: MenuButton = %FileMenuButton
@onready var edit_menu_button: MenuButton = %EditMenuButton
@onready var help_menu_button: MenuButton = %HelpMenuButton
@onready var status_message_label: Label = %StatusMessageLabel
# @onready var version_label: Label = %VersionLabel

@onready var status_message_timer: Timer = %StatusMessageTimer
@onready var video_edit_panel: VideoEditPanel = %VideoEditPanel


func _ready() -> void:
    render_test_button.pressed.connect(func(): VideoManager.render())
    VideoManager.viewport = video_viewport
    VideoManager.setup_playback()
    EventBus.project_name_changed.connect(_on_project_name_changed)
    EventBus.project_saved.connect(_on_project_saved)
    EventBus.status_message_sended.connect(_on_status_message_sended)

    EventBus.video_changed.connect(open_video)
    EventBus.video_paused.connect(func(b): play_button.button_pressed = b)
    EventBus.video_sought.connect(func(t): seek_time(t))
    EventBus.jump_to_here_requested.connect(func(time):
        seek_time(time)
        update_subtitles()
    )

    EventBus.ai_translate_progress_updated.connect(func(progress):
        ProjectManager.send_status_message("AI translate progress: %.2f" % progress)
    )
    EventBus.ai_translate_finished.connect(func():
        ProjectManager.send_status_message("AI translate finished")
    )

    play_button.toggled.connect(_on_play_button_toggled)
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
    file_menu_popup.theme_type_variation = "GosubPopupMenu"
    @warning_ignore_start("int_as_enum_without_cast")
    @warning_ignore_start("int_as_enum_without_match")
    file_menu_popup.add_item("Select Project", 0, KEY_MASK_CTRL | KEY_E)
    file_menu_popup.add_item("Save Project", 1, KEY_MASK_CTRL | KEY_S)
    file_menu_popup.add_separator()
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
    edit_menu_popup.theme_type_variation = "GosubPopupMenu"
    edit_menu_popup.add_item("Settings", 0, KEY_MASK_CTRL | KEY_P)
    edit_menu_popup.id_pressed.connect(func(id):
        match id:
            0:
                ProjectManager.show_settings_popup()
    )

    var help_menu_popup = help_menu_button.get_popup()
    help_menu_popup.theme_type_variation = "GosubPopupMenu"
    help_menu_popup.add_item("About", 0)
    help_menu_popup.id_pressed.connect(func(id):
        match id:
            0:
                ProjectManager.show_message("About", "This is a test message.")
    )
    @warning_ignore_restore("int_as_enum_without_cast")
    @warning_ignore_restore("int_as_enum_without_match")

    status_message_label.text = Constant.DEFAULT_STATUS_MESSAGE
    status_message_timer.wait_time = 2.0
    status_message_timer.timeout.connect(_on_status_message_timeout)

    # theme init
    menu_bar_stylebox = get_theme_stylebox("menu_bar", "Main")
    bg_stylebox = get_theme_stylebox("main_bg", "Main")

    Profiler.start("ProjectManager.show_select_project_popup")
    ProjectManager.show_select_project_popup()
    Profiler.stop("ProjectManager.show_select_project_popup")

    queue_redraw.call_deferred()


func _draw() -> void:
    draw_style_box(menu_bar_stylebox, Rect2(Vector2.ZERO, menu_bar.size))
    draw_style_box(bg_stylebox, Rect2(Vector2(0, menu_bar.size.y), hsplit_container.size))


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
    VideoManager.process(delta)
    time_label.text = VideoManager.get_time_label_text()
    update_subtitles()
    video_edit_panel.on_process(VideoManager.get_current_time())


func open_video(filepath: String):
    if not is_node_ready():
        await ready

    if not FileAccess.file_exists(filepath):
        return

    Logger.info("Video Path: %s" % filepath)

    VideoManager.open_video(filepath)


func seek_time(time: float):
    VideoManager.seek_frame(ceili(time * VideoManager.frame_rate))


func play(flag: bool):
    VideoManager.play(flag)


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
        var current_time = VideoManager.get_current_time()
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
#endregion


func _on_project_name_changed(project_name: String) -> void:
    Logger.info("Project name changed: %s" % project_name)
    var suffix = "*" if ProjectManager.current_project.dirty else ""
    project_name_edit.text = project_name + suffix


func _on_project_saved() -> void:
    project_name_edit.text = ProjectManager.current_project.project_name


func _on_status_message_sended(message: String) -> void:
    status_message_label.text = message
    # status_message_timer.start()


func _on_status_message_timeout() -> void:
    status_message_label.text = Constant.DEFAULT_STATUS_MESSAGE
