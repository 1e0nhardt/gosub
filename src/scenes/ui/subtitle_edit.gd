class_name SubtitleEdit
extends CodeEdit

signal yield_focus

var default_background_color: Color
var last_highlight_clip_index: int = 0

var subtitle_track: SubtitleTrack:
    get(): return ProjectManager.current_project.subtitle_track


func _ready():
    EventBus.subtitle_loaded.connect(load_subtitle)
    EventBus.subtitle_clip_index_updated.connect(_on_subtitle_clip_index_updated)
    EventBus.subtitle_clips_updated.connect(func():
        text = subtitle_track.get_full_text()
        focus_clip(subtitle_track.current_clip_index)
    )
    EventBus.project_saved.connect(save_subtitle)

    default_background_color = get_line_background_color(0)

    # 右键菜单
    var menu = get_menu()
    menu.item_count = menu.get_item_index(MENU_REDO) + 1
    menu.add_separator()
    # Bug? accl不起作用，还有参数类型warning。
    menu.add_item("Jump Play", MENU_MAX + 1)
    menu.id_pressed.connect(func(id):
        match id:
            MENU_MAX + 1:
                @warning_ignore("integer_division")
                EventBus.jump_to_here_requested.emit(subtitle_track.subtitle_clips[get_caret_line() / 4].start_time + 0.02)
    )

    load_subtitle()
    if text != "":
        highlight_clip(0)


func _gui_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        yield_focus.emit()
        release_focus()


func load_subtitle():
    if subtitle_track.num_clips == 0:
        return

    text = subtitle_track.get_full_text()


func save_subtitle():
    if subtitle_track.num_clips == 0:
        return

    #TODO 检查文本的合法性
    subtitle_track.update_subtitle_clips(text)
    subtitle_track.export_subtitle_file()


func highlight_clip(clip_index: int):
    var lineno = clip_index * 4
    var last_lineno = last_highlight_clip_index * 4
    set_line_background_color(last_lineno, default_background_color)
    set_line_background_color(last_lineno + 1, default_background_color)
    set_line_background_color(last_lineno + 2, default_background_color)
    set_line_background_color(lineno, Color.DARK_OLIVE_GREEN)
    set_line_background_color(lineno + 1, Color.DARK_OLIVE_GREEN)
    set_line_background_color(lineno + 2, Color.DARK_OLIVE_GREEN)
    last_highlight_clip_index = clip_index


func focus_clip(clip_index: int) -> void:
    highlight_clip(clip_index)
    set_line_as_center_visible(subtitle_track.current_clip_index * 4)


func _on_subtitle_clip_index_updated():
    focus_clip(subtitle_track.current_clip_index)
