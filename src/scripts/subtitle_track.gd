class_name SubtitleTrack
extends RefCounted

var subtitle_filepath: String = "temp.ass"
var subtitle_clips: Array[SubtitleClip]
var num_clips: int:
    get: return subtitle_clips.size()

var current_clip_index: int = -1:
    set(value):
        current_clip_index = value
        EventBus.subtitle_clip_index_updated.emit()

var current_clip: SubtitleClip:
    get:
        if is_empty():
            return null
        return subtitle_clips[current_clip_index]
var prev_clip_start_time:
    get: return subtitle_clips[max(current_clip_index - 1, 0)].start_time
var next_clip_start_time:
    get: return subtitle_clips[min(current_clip_index + 1, num_clips)].start_time

var long_sentence_limit: int = 42


## 加载字幕文件
func load_subtitle(filepath: String):
    subtitle_filepath = filepath
    subtitle_clips = Util.parse_subtitle_file(filepath)
    current_clip_index = 0
    # Logger.info(subtitle_clips)
    EventBus.subtitle_loaded.emit()


## 将文本更新保存到内存
func update_subtitle_clips(content: String) -> void:
    subtitle_clips = Util.parse_edit_text(content)


func merge_with_next_clip() -> void:
    if current_clip_index == num_clips - 1:
        return

    var next_clip = subtitle_clips[current_clip_index + 1]
    current_clip.end = next_clip.end
    current_clip.first_text += next_clip.first_text
    current_clip.second_text += next_clip.second_text
    subtitle_clips.remove_at(current_clip_index + 1)


func try_update_current_clip_with_clips(clips: Array) -> void:
    if clips.size() == 0:
        return

    if clips[0].first_text == "":
        clips[0].first_text = current_clip.first_text

    clips.reverse()
    for clip in clips:
        subtitle_clips.insert(current_clip_index + 1, clip)

    subtitle_clips.remove_at(current_clip_index)
    EventBus.subtitle_clips_updated.emit()


func get_next_long_sentence_index() -> int:
    var i = current_clip_index + 1
    while i < num_clips:
        if subtitle_clips[i].first_text.length() > long_sentence_limit:
            return i
        i += 1
    return -1


func export_subtitle_file(filepath: String = "", only_first = false) -> void:
    if not filepath:
        filepath = ProjectManager.current_project.get_save_basename() + ".ass"

    if subtitle_clips.size() == 0:
        Logger.warn("No valid clips exists!")
        return

    var export_file = FileAccess.open(filepath, FileAccess.WRITE)

    # 确保时间不会交错
    for i in subtitle_clips.size() - 1:
        if subtitle_clips[i + 1].start < subtitle_clips[i].end:
            Logger.warn("Clip time intersect at index %d, %s<->%s. Fixed." % [
                i, subtitle_clips[i].get_end_timestamp(), subtitle_clips[i + 1].get_start_timestamp()])
            subtitle_clips[i].end = subtitle_clips[i + 1].start

    var content: String = ""
    if filepath.get_extension() == "ass":
        content += ProjectManager.get_setting_value("/subtitle/ass/template")
        for clip in subtitle_clips:
            if only_first:
                content += Util.ASS_DIALOG_FORMAT_ONLY_FIRST % [
                    0, # layer
                    clip.get_start_timestamp(),
                    clip.get_end_timestamp(),
                    clip.first_text,
                ]
            else:
                content += Util.ASS_DIALOG_FORMAT % [
                    0, # layer
                    clip.get_start_timestamp(),
                    clip.get_end_timestamp(),
                    clip.first_text, clip.second_text
                ]
        export_file.store_string(content)
    else:
        #TODO 暂时只支持ASS格式
        export_file.store_string(get_full_text())


func get_full_text() -> String:
    var full_text := ""
    for clip in subtitle_clips:
        full_text += clip.full_edit_text()
    return full_text


func is_empty() -> bool:
    return num_clips == 0


func clear() -> void:
    subtitle_clips.clear()
    current_clip_index = -1
    EventBus.subtitle_clips_updated.emit()


## 随时间更新current_clip_index和高亮区域
func update(play_time: float):
    if is_empty():
        return

    var ret = current_clip.compare(play_time)

    if ret == 0:
        return
    elif ret == 1:
        var next_index = current_clip_index + 1
        if next_index >= num_clips:
            return

        if subtitle_clips[next_index].compare(play_time) == 0:
            current_clip_index = next_index
            return

        current_clip_index = bin_search(play_time, current_clip_index, num_clips - 1)
    else:
        current_clip_index = bin_search(play_time, 0, current_clip_index)


func bin_search(play_time: float, left: int, right: int) -> int:
    while left <= right:
        @warning_ignore("integer_division")
        var mid = left + (right - left) / 2
        var ret = subtitle_clips[mid].compare(play_time)
        if ret == 0:
            return mid # 找到目标值，返回其索引
        elif ret == 1:
            left = mid + 1 # 调整搜索区间到右半部分
        else:
            right = mid - 1 # 调整搜索区间到左半部分

    # 直接跳到最后一个clip后的时间段，left会超出数组范围
    return clampi(left, 0, num_clips - 1)
