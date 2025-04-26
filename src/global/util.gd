class_name Util
extends Node

const ASS_DIALOG_FORMAT = "Dialogue: %d,%s,%s,ZH,,0,0,0,,%s\\N{\\rEN}%s\n"
const ASS_DIALOG_FORMAT_ONLY_FIRST = "Dialogue: %d,%s,%s,ZH,,0,0,0,,%s\n"

static var start_time: int


static func get_parent_dir(filepath: String) -> String:
    return filepath.rsplit("/", true, 1)[0]


static func get_stem(filepath: String) -> String:
    return filepath.rsplit("/", true, 1)[1].split(".")[0]


static func reset_start_time():
    start_time = Time.get_ticks_usec()


@warning_ignore_start("integer_division")
static func print_time_cost(desc: String = "Segment"):
    var msg := ""
    var time_cost: int = Time.get_ticks_usec() - start_time
    var us = time_cost - time_cost / 1000 * 1000
    time_cost /= 1000
    if time_cost == 0:
        msg = "%s time cost: %dus" % [desc, us]
    else:
        var ms = time_cost - time_cost / 1000 * 1000
        time_cost /= 1000
        if time_cost == 0:
            msg = "%s time cost: %d_%03dus" % [desc, ms, us]
        else:
            msg = "%s time cost: %d_%03d_%03dus" % [desc, time_cost, ms, us]
    Logger.info(msg)


static func time_ms2str(millisecond: int, format = "ass") -> String:
    var seconds = millisecond / 1000
    var ms = millisecond - seconds * 1000
    var minutes = seconds / 60
    seconds %= 60
    var hours = minutes / 60
    minutes %= 60
    if format == "ass":
        ms /= 10
        return "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, ms]
    else:
        return "%02d:%02d:%02d,%03d" % [hours, minutes, seconds, ms]


static func time_float2str(time: float, format = "ass") -> String:
    return time_ms2str(int(time * 1000), format)
@warning_ignore_restore("integer_division")


static func time_str2float(time_str: String, format = "ass") -> float:
    var tmp_arr = time_str.strip_edges().split(':')
    var hrs = tmp_arr[0]
    var mins = tmp_arr[1]
    var sec_ms = tmp_arr[2]
    var seconds
    var ms
    if format == "ass":
        tmp_arr = sec_ms.split(".")
        ms = int(tmp_arr[1]) / 100.0
    else:
        tmp_arr = sec_ms.split(",")
        ms = int(tmp_arr[1]) / 1000.0
    seconds = tmp_arr[0]
    return float(int(hrs) * 3600 + int(mins) * 60 + int(seconds)) + ms


static func time_str2ms(time_str: String, format = "ass") -> int:
    return int(time_str2float(time_str, format) * 1000)


static func parse_subtitle_file(filepath: String) -> Array[SubtitleClip]:
    var content = FileAccess.get_file_as_string(filepath)
    if filepath.get_extension() == "ass":
        return parse_ass_file(content)
    else:
        Logger.warn("Not supportted format %s" % filepath.get_extension())
        return []


static func parse_ass_file(content: String) -> Array[SubtitleClip]:
    var subtitle_clips: Array[SubtitleClip] = []
    var current_section = ""
    var lines: Array = content.split("\n")
    var line_text: String
    for i in lines.size():
        line_text = lines[i]
        if i == 0:
            # 文件开头可能有BOM头\ufeff，因此用==判断会出错
            assert("[Script Info]" in line_text, "ass文件内容格式错误")
            continue

        if line_text.strip_edges() == "[V4+ Styles]":
            current_section = "style"
            continue
        elif line_text.strip_edges() == "[Events]":
            current_section = "events"
            continue
        elif line_text.begins_with("Format"):
            continue

        if current_section == "events":
            if line_text.strip_edges() == "" or line_text.begins_with("Comment"):
                continue
            elif line_text.begins_with("Dialogue"):
                var subtitle_clip := SubtitleClip.new()
                var params = line_text.split(": ", true, 1)[1].split(",", true, 9)
                subtitle_clip.start = Util.time_str2ms(params[1])
                subtitle_clip.end = Util.time_str2ms(params[2])
                var subtitle_text = params[9]
                #Logger.debug("%s" % subtitle_text)
                if subtitle_text.find("\\N{\\rEN}") != -1:
                    subtitle_clip.first_text = subtitle_text.split("\\N{\\rEN}")[0]
                    subtitle_clip.second_text = subtitle_text.split("\\N{\\rEN}")[1]
                else:
                    subtitle_clip.second_text = params[9]
                subtitle_clips.append(subtitle_clip)
            else:
                Logger.warn("ASS FORMAT INVALID at %d: %s" % [i, lines[i]])
        elif current_section == "style":
            continue
            #if line_text.begins_with("Style"):
                #var params = line_text.split(": ")[1].split(",")
                #self.valid_style_names.append(params[0])
        else:
            continue

    return subtitle_clips


static func parse_edit_text(content: String) -> Array[SubtitleClip]:
    var subtitle_clips: Array[SubtitleClip] = []
    var lines: Array = content.split("\n")
    var treg := RegEx.new()
    var reg_match: RegExMatch
    treg.compile(r"\[(.*)->(.*)\]")

    var i = 0
    while i < lines.size():
        var subtitle_clip = SubtitleClip.new()
        # 时间行
        reg_match = treg.search(lines[i].strip_edges())
        if reg_match:
            subtitle_clip.start = Util.time_str2ms(reg_match.get_string(1))
            subtitle_clip.end = Util.time_str2ms(reg_match.get_string(2))
        else:
            Logger.warn("Time label is invalid! => %s" % lines[i])
        i += 1
        # 第一语言字幕
        subtitle_clip.first_text = lines[i].strip_edges()
        i += 1
        # 第二语言字幕
        subtitle_clip.second_text = lines[i].strip_edges()
        i += 1
        subtitle_clips.append(subtitle_clip)

        # 跳过空行
        while i < lines.size() and lines[i].strip_edges() == "":
            i += 1

    return subtitle_clips


static func is_space(c: String) -> bool:
    return c in " \t"


static func is_white_space(c: String) -> bool:
    return c in "\t\n\v\f\r "


static func remove_escape_char(s: String) -> String:
    var ret = ""
    var i = 0
    while i < s.length():
        if s[i] == "\\":
            i += 1
            if i >= s.length():
                break
            ret += s[i]
        else:
            ret += s[i]
        i += 1
    return ret


static func get_current_timestamp() -> String:
    var dict := Time.get_datetime_dict_from_system()
    return "%04d%02d%02d%02d%02d%02d" % [dict["year"], dict["month"], dict["day"], dict["hour"], dict["minute"], dict["second"]]


static func check_path(path: String) -> bool:
    if path == "":
        Logger.info("path is empty")
        return false

    if not FileAccess.file_exists(path):
        Logger.info("File not found: " + path)
        return false
    return true


static func ensure_dir(path: String) -> void:
    if path == "":
        Logger.warn("path is empty")
        return

    if not DirAccess.dir_exists_absolute(path):
        DirAccess.make_dir_recursive_absolute(path)


static func delete_folder_recursive(path: String) -> void:
    var dir = DirAccess.open(path)
    if not dir:
        Logger.warn("Fail to open folder: " + path)
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if dir.current_is_dir():
            delete_folder_recursive(path + "/" + file_name)
        else:
            dir.remove(file_name)
        file_name = dir.get_next()
    dir.list_dir_end()
    dir.remove(path)


static func center_main_window(window: Window, window_size: Vector2i) -> void:
    var screen_size = DisplayServer.screen_get_size()
    window.size = window_size
    var centered_pos = (screen_size - window_size) / 2
    window.position = centered_pos


static func calculate_audio_wave_envelope(audio_data: PackedByteArray, frames_per_block: int = 256) -> Array:
    var pos_envelope: Array = []
    var neg_envelope: Array = []
    if audio_data.is_empty():
        Logger.warn("Audio data is empty!")
        return [[], []]

    var bytes_size: float = 4 # 16 bit * stereo
    var total_frames: int = int(audio_data.size() / bytes_size)
    var total_blocks: int = ceili(float(total_frames) / frames_per_block)
    var current_frame_index: int = 0

    pos_envelope.resize(total_blocks)
    neg_envelope.resize(total_blocks)

    for i: int in total_blocks:
        var max_abs_amplitude: float = 0.0
        var min_abs_amplitude: float = 0.0
        var start_frame: int = current_frame_index
        var end_frame: int = min(start_frame + frames_per_block, total_frames)

        for frame_index: int in range(start_frame, end_frame):
            var byte_offset: int = int(frame_index * bytes_size)
            var frame_max_amplitude: float = 0.0
            var frame_min_amplitude: float = 0.0

            if byte_offset + bytes_size > audio_data.size():
                Logger.info("Attempted to read past end of audio data at frame %d." % frame_index)
                break

            var left_sample: int = audio_data.decode_s16(byte_offset)
            var right_sample: int = audio_data.decode_s16(byte_offset + 2)

            frame_max_amplitude = max(float(left_sample), float(right_sample))
            frame_min_amplitude = min(float(left_sample), float(right_sample))

            if frame_max_amplitude > max_abs_amplitude:
                max_abs_amplitude = frame_max_amplitude

            if frame_min_amplitude < min_abs_amplitude:
                min_abs_amplitude = frame_min_amplitude

        pos_envelope[i] = clamp(max_abs_amplitude / Constant.MAX_16_BITS_VALUE, 0.0, 1.0)
        neg_envelope[i] = clamp(min_abs_amplitude / Constant.MAX_16_BITS_VALUE, -1.0, 0.0)

        current_frame_index = end_frame

    return [pos_envelope, neg_envelope]