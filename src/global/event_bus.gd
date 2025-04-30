extends Node

@warning_ignore_start("unused_signal")
signal project_name_changed(new_name: String)
signal project_saved
signal project_loaded
signal status_message_sended(message: String)

signal pipeline_stage_changed(stage: int)
signal pipeline_started
signal pipeline_finished

signal video_changed(path: String)
signal jump_to_here_requested(time: float)
signal video_paused(pause_or_play: bool)

signal subtitle_clip_index_updated
signal subtitle_loaded
signal subtitle_clips_updated
signal clips_translated(clips: Array)
signal asr_popup_closed

signal ai_translate_progress_updated(progress: float)
signal ai_translate_finished
@warning_ignore_restore("unused_signal")