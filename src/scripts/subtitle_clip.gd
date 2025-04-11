class_name SubtitleClip
extends Clip

var first_text = ""
var second_text = ""


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