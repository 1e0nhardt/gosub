extends Node

@warning_ignore_start("unused_signal")
signal project_name_changed(new_name: String)
signal project_saved

signal pipeline_stage_changed(stage: int)

signal video_changed(path: String)
signal jump_to_here_requested(time: float)
signal video_paused(pause_or_play: bool)

signal subtitle_clip_index_updated
signal subtitle_loaded

signal ai_translate_progress_updated(progress: float)
signal ai_translate_finished
@warning_ignore_restore("unused_signal")