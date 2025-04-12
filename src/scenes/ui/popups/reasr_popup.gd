class_name ReasrPopup
extends PopupManager.PopupControl

@onready var text_edit: TextEdit = %TextEdit
@onready var translate_button: Button = %TranslateButton
@onready var split_button: Button = %SplitButton
@onready var cancel_button: Button = %CancelButton
@onready var ok_button: Button = %OkButton

var json_data: Dictionary
var new_clips := []


func _ready() -> void:
    ok_button.disabled = true
    EventBus.clips_translated.connect(_on_clips_translated)

    about_to_popup.connect(update_text_edit)
    translate_button.pressed.connect(_on_translate_pressed)
    split_button.pressed.connect(_on_split_pressed)
    cancel_button.pressed.connect(close_popup)
    ok_button.pressed.connect(_on_ok_pressed)

    var menu = text_edit.get_menu()
    menu.item_count = 0
    menu.add_item("分割", TextEdit.MENU_MAX + 1)
    menu.id_pressed.connect(func(id):
        match id:
            TextEdit.MENU_MAX + 1:
                var caret_line_num = text_edit.get_caret_line()
                var caret_column_num = text_edit.get_caret_column()
                var line = text_edit.get_line(caret_line_num)
                var split_pos = line.find(" ", caret_column_num)
                if split_pos != -1:
                    text_edit.set_caret_column(split_pos)
                    text_edit.insert_text_at_caret("\n")
                else:
                    Logger.debug("Already at the end of the line. Or no space found.")
    )


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    ProjectManager.show_blocker()
    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)
    ProjectManager.hide_blocker()


func update_text_edit() -> void:
    if not json_data:
        Logger.warn("No json data.")
        return

    var data = json_data["transcription"]
    var data_len = len(data)
    var clip := SubtitleClip.new()
    var content := ""

    for i in range(data_len):
        var segment = data[i]
        content = segment["text"]
        clip.second_text += content

        if i == 0:
            clip.start = segment["offsets"]["from"]

        if i == data_len - 1:
            clip.end = segment["offsets"]["to"]

    text_edit.text = clip.second_text


func _on_translate_pressed() -> void:
    new_clips = text_to_clips()
    DeepSeekApi.translate_clips(new_clips)


func _on_clips_translated(clips):
    for clip in clips:
        text_edit.text += clip.full_edit_text()
    new_clips = clips
    ok_button.disabled = false


func _on_ok_pressed() -> void:
    ProjectManager.current_project.subtitle_track.try_update_current_clip_with_clips(new_clips)
    close_popup()


func _on_split_pressed() -> void:
    new_clips = text_to_clips()
    ProjectManager.current_project.subtitle_track.try_update_current_clip_with_clips(new_clips)
    close_popup()


func text_to_clips() -> Array:
    var text = text_edit.text.strip_edges()
    var splits := text.split("\n")
    var data: Array = json_data["transcription"].filter(func(e): return e["text"] != "")
    var index = 0
    var clips := []
    for split in splits:
        var word_num = split.strip_edges().split(" ").size()
        var clip = SubtitleClip.new()
        clip.second_text = split
        clip.start = data[index]["offsets"]["from"]
        clip.end = data[index + word_num - 1]["offsets"]["to"]
        index += word_num
        clips.append(clip)
    return clips
