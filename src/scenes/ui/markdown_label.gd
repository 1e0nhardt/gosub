class_name MarkdownLabel
extends RichTextLabel

@export var is_sender: bool = true

var sender_stylebox: StyleBox
var response_stylebox: StyleBox


func _ready() -> void:
    sender_stylebox = get_theme_stylebox("sender_message", "DeepseekChatContainer")
    response_stylebox = get_theme_stylebox("response_message", "DeepseekChatContainer")
    add_theme_stylebox_override("normal", sender_stylebox if is_sender else response_stylebox)
    size_flags_horizontal = Control.SIZE_SHRINK_END if is_sender else Control.SIZE_SHRINK_BEGIN
    adjust_minimum_width.call_deferred()


func set_content(content: String) -> void:
    text = content
    adjust_minimum_width()


func adjust_minimum_width() -> void:
    var font := get_theme_font("font")
    var font_size = get_theme_font_size("font_size")
    var width = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + sender_stylebox.content_margin_left + sender_stylebox.content_margin_right

    var parent = get_parent()
    if parent is Container:
        if width < parent.size.x:
            custom_minimum_size.x = width
        else:
            custom_minimum_size.x = parent.size.x

    queue_redraw()


func _on_meta_clicked(meta):
    print("Clicked on meta:", meta)

    if meta.begins_with("http"):
        OS.shell_open(meta)
        return

    var json = JSON.new()
    var error = json.parse(meta)
    if error == OK:
        var json_dict = json.data
        if typeof(json_dict) == TYPE_DICTIONARY:
            print(json_dict["annotation"])
        else:
            print("Unexpected data %s" % json_dict)


func _on_meta_hover_started(meta: Variant) -> void:
    print("Hover on meta start:", meta)


func _on_meta_hover_ended(meta: Variant) -> void:
    print("Hover on meta end:", meta)
