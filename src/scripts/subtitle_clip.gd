class_name SubtitleClip
extends Clip

var first_text = ""
var second_text = ""

var _splited_clips: Array[SubtitleClip] = []

func load_from_json(json_data: Dictionary) -> void:
    first_text = json_data["text"]
    start = json_data["offsets"]["from"]
    end = json_data["offsets"]["to"]


func full_edit_text() -> String:
    return "[%s->%s]\n%s\n%s\n\n" % [get_start_timestamp(), get_end_timestamp(), first_text, second_text]


func ass_dialog_line() -> String:
    return "Dialogue: 0,%s,%s,ZH,,0,0,0,,%s\\N{\\rEN}%s\n" % [get_start_timestamp(), get_end_timestamp(), first_text, second_text]


func list_line() -> String:
    return "[%s->%s]%s\n" % [get_start_timestamp(), get_end_timestamp(), second_text]


func _to_string() -> String:
    return "[%s(%d)->%s(%d)]%s -- %s" % [get_start_timestamp(), start, get_end_timestamp(), end, first_text, second_text]


func split_long_sentences(json: Dictionary) -> void:
    var message = ProjectManager.get_setting_value("/llm/common/prompt/punctuation") + "\n" + second_text
    DeepSeekApi.punctuation_once(message)
    await DeepSeekApi.punctuation_message_received
    var result = DeepSeekApi.received_punctuation_message
    var result_data = result.split(" ", false)

    var new_clips: Array[SubtitleClip] = []
    var data = json["transcription"]
    var start_index: int = 0
    var end_index: int = 0
    for i in range(len(data)):
        if data[i]["offsets"]["from"] == start:
            start_index = i

        if data[i]["offsets"]["to"] == end:
            end_index = i
            break

    var clip := SubtitleClip.new()
    var content = ""
    var empty_compensation = 0
    for i in range(start_index, end_index + 1):
        var segment = data[i]
        if segment["text"] == "":
            empty_compensation += 1
            continue

        content = result_data[i - empty_compensation - start_index]
        clip.second_text += " " + content

        # 最后一个句子。可能不是以`.`结尾的。
        if i == len(data) - 1:
            clip.end = segment["offsets"]["to"]
            new_clips.append(clip)

        if i == start_index or clip.start == 0:
            clip.start = segment["offsets"]["from"]

        # try split long sentence
        if content.ends_with(","):
            if segment["offsets"]["to"] - clip.start > ProjectManager.get_setting_value("/transcribe/whisper.cpp/smart_split_threshold") * 1000:
                clip.end = segment["offsets"]["to"]
                new_clips.append(clip)
                clip = SubtitleClip.new()

        if content[-1] in ".!?！？。":
            clip.end = segment["offsets"]["to"]
            new_clips.append(clip)
            clip = SubtitleClip.new()

    _splited_clips = new_clips
