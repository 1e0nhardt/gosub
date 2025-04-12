class_name SubtitleEditContainer
extends VBoxContainer

@onready var subtitle_edit: SubtitleEdit = %SubtitleEdit
@onready var prev_clip_button: Button = %PrevClipButton
@onready var next_clip_button: Button = %NextClipButton
@onready var combine_next_button: Button = %CombineNextButton
@onready var reasr_button: Button = %ReasrButton
@onready var goto_next_long_sentence_button: Button = %GotoNextLongSentenceButton


func _ready() -> void:
    prev_clip_button.pressed.connect(_on_prev_clip_button_pressed)
    next_clip_button.pressed.connect(_on_next_clip_button_pressed)
    goto_next_long_sentence_button.pressed.connect(_on_goto_next_long_sentence_button_pressed)
    combine_next_button.pressed.connect(_on_combine_next_button_pressed)
    reasr_button.pressed.connect(_on_reasr_button_pressed)

    # 编辑时暂停，按esc退出编辑，继续播放。
    subtitle_edit.focus_entered.connect(func(): EventBus.video_paused.emit(false))
    subtitle_edit.yield_focus.connect(func(): EventBus.video_paused.emit(true))


#region SubtitleEdit Buttons
func _on_next_clip_button_pressed():
    EventBus.jump_to_here_requested.emit(subtitle_edit.subtitle_track.next_clip_start_time + 0.01)


func _on_prev_clip_button_pressed():
    EventBus.jump_to_here_requested.emit(subtitle_edit.subtitle_track.prev_clip_start_time + 0.01)


func _on_goto_next_long_sentence_button_pressed():
    var target_index = subtitle_edit.subtitle_track.get_next_long_sentence_index()
    if target_index == -1:
        return
    else:
        subtitle_edit.subtitle_track.current_clip_index = target_index
        EventBus.jump_to_here_requested.emit(subtitle_edit.subtitle_track.current_clip.start_time + 0.01)


func _on_combine_next_button_pressed():
    subtitle_edit.subtitle_track.merge_with_next_clip()
    subtitle_edit.text = subtitle_edit.subtitle_track.get_full_text()
    subtitle_edit.focus_clip(subtitle_edit.subtitle_track.current_clip_index)


func _on_reasr_button_pressed():
    if subtitle_edit.subtitle_track.num_clips == 0:
        return

    EventBus.video_paused.emit(false)
    reasr_button.disabled = true

    ExecuterThreadPool.request_thread_execution(
        {
            "type": "transcribe_segment",
            "audio_path": ProjectManager.current_project.audio_path,
            "from": subtitle_edit.subtitle_track.current_clip.start,
            "to": subtitle_edit.subtitle_track.current_clip.end
        },
        func(response: Dictionary):
            reasr_button.disabled = false

            var err_flag = response["succeed"]
            if not err_flag:
                Logger.warn("Transcribe failed!")
                return

            ProjectManager.show_asr_edit(response["data"])
    )
#endregion
