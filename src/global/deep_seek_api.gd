extends Node

signal message_received(content: String)
signal translate_message_received(content: String)
signal stream_data_received(content: String)

## for DeepSeekChatContainer
var deepseek_chat_stream: DeepSeekChatStream
## for translate
var deepseek_chat_normal: DeepseekChatNormal
var deepseek_chat_translate: DeepseekChatNormal
var received_translate_message: String = ""

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var http_request_translate: HTTPRequest = $HTTPRequestTranslate


func _ready() -> void:
    deepseek_chat_stream = DeepSeekChatStream.new()
    deepseek_chat_normal = DeepseekChatNormal.new(http_request)
    deepseek_chat_translate = DeepseekChatNormal.new(http_request_translate)
    deepseek_chat_normal.message_received.connect(
        func(c):
            message_received.emit(c)
    )
    deepseek_chat_translate.message_received.connect(
        func(c):
            received_translate_message = c
            translate_message_received.emit(c)
    )
    deepseek_chat_stream.stream_data_received.connect(func(c): stream_data_received.emit.call_deferred(c))


func chat(message: String, use_normal: bool = false) -> void:
    if use_normal:
        deepseek_chat_normal.send_message(message)
    else:
        deepseek_chat_stream.send_message(message)


func chat_once(message: String, use_normal: bool = false) -> void:
    if use_normal:
        deepseek_chat_normal.send_message_without_history.call_deferred(message)
    else:
        deepseek_chat_stream.send_message_without_history(message)


func translate_once(message: String) -> void:
    deepseek_chat_translate.send_message_without_history.call_deferred(message)


func clear_history(use_normal: bool = false) -> void:
    if use_normal:
        deepseek_chat_normal.clear_history_messages()
    else:
        deepseek_chat_stream.clear_history_messages()


func poll() -> void:
    deepseek_chat_stream.poll()


func json_to_clips(json_path: String) -> bool:
    if FileAccess.file_exists(json_path) == false:
        Logger.info("json file not exists: %s" % json_path)
        ProjectManager.show_message("Error", "Transcribe result file not exist! Please redo transcribe by click reasr button!")
        EventBus.pipeline_finished.emit()
        return false

    var json = JSON.parse_string(FileAccess.get_file_as_string(json_path))
    var data = json["transcription"]
    var clips: Array[SubtitleClip] = []
    var clip := SubtitleClip.new()
    var content := ""

    # -ml 1
    if ProjectManager.get_setting_value("/transcribe/whisper.cpp/smart_split"):
        for i in range(len(data)):
            var segment = data[i]
            if segment["text"] == "":
                continue

            content = segment["text"]
            clip.second_text += content

            if i == 0 or clip.start == 0:
                clip.start = segment["offsets"]["from"]

            # try split long sentence
            if content.ends_with(","):
                if segment["offsets"]["to"] - clip.start > ProjectManager.get_setting_value("/transcribe/whisper.cpp/smart_split_threshold") * 1000:
                    clip.end = segment["offsets"]["to"]
                    clips.append(clip)
                    clip = SubtitleClip.new()

            if content[-1] in ".!?！？。":
                clip.end = segment["offsets"]["to"]
                clips.append(clip)
                clip = SubtitleClip.new()
    else:
        for i in range(len(data)):
            var segment = data[i]
            if segment["text"] == "":
                continue

            clip = SubtitleClip.new()
            content = segment["text"]
            clip.second_text += content
            clip.start = segment["offsets"]["from"]
            clip.end = segment["offsets"]["to"]
            clips.append(clip)

    var start_time = Time.get_ticks_msec()
    deepseek_chat_translate.set_system_prompt.call_deferred(ProjectManager.get_setting_value("/llm/common/prompt/translate"))
    EventBus.ai_translate_progress_updated.emit.call_deferred(0)
    var source_contents := ""

    var clips_one_chat: int = ProjectManager.get_setting_value("/llm/common/clips_per_chat")
    for i in range(0, len(clips), clips_one_chat):
        for j in clips_one_chat:
            if i + j >= len(clips):
                break
            source_contents += clips[i + j].list_line()

        translate_once(source_contents)
        await translate_message_received
        var result = received_translate_message
        var result_contents = result.split("\n")
        for j in range(len(result_contents)):
            var r = result_contents[j].strip_edges()
            if not r.begins_with("["):
                Logger.info("Unexpected result: " + r)
                clips[i + j].first_text = "Translate Error"
            else:
                clips[i + j].first_text = r.split("]")[1].strip_edges()
        source_contents = ""
        received_translate_message = ""

        EventBus.ai_translate_progress_updated.emit.call_deferred(clampf(float(i + 8) / len(clips), 0, 1))

    EventBus.ai_translate_progress_updated.emit.call_deferred(1)
    ProjectManager.current_project.subtitle_track.subtitle_clips = clips
    # Logger.info(clips)
    ProjectManager.current_project.subtitle_track.export_subtitle_file()
    EventBus.ai_translate_finished.emit.call_deferred()

    Logger.info("translate time cost: %s" % Util.time_ms2str(Time.get_ticks_msec() - start_time))
    return true


func translate_clips(clips: Array) -> void:
    deepseek_chat_translate.set_system_prompt.call_deferred(ProjectManager.get_setting_value("/llm/common/prompt/translate"))
    var source_contents := ""

    for i in range(0, len(clips), 8):
        for j in 8:
            if i + j >= len(clips):
                break
            source_contents += clips[i + j].list_line()

        translate_once(source_contents)
        await translate_message_received
        var result = received_translate_message
        var result_contents = result.split("\n")
        for j in range(len(result_contents)):
            if result_contents[j].begins_with("[") == false:
                Logger.info("Unexpected result: " + result_contents[j])
                continue

            clips[i + j].first_text = result_contents[j].split("]")[1].strip_edges()
        source_contents = ""
        received_translate_message = ""

    EventBus.clips_translated.emit.call_deferred(clips)
