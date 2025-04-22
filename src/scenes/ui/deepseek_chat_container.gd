class_name DeepSeekChatContainer
extends VBoxContainer

const MARKDOWN_LABEL_SCENE := preload("res://scenes/ui/markdown_label.tscn")

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var messages_vbox: VBoxContainer = %MessagesVBox
@onready var message_edit: TextEdit = %MessageEdit
@onready var send_button: Button = %SendButton
@onready var panel_container: PanelContainer = %PanelContainer

var received_stream_content := ""
var message_label: MarkdownLabel = null
var message_box: VBoxContainer = null


func _ready() -> void:
    panel_container.add_theme_stylebox_override("panel", get_theme_stylebox("message_input", "DeepseekChatContainer"))
    send_button.pressed.connect(_on_send_button_pressed)
    # DeepSeekApi.message_received.connect(_on_message_received)
    DeepSeekApi.stream_data_received.connect(_on_stream_data_received)
    message_edit.text_changed.connect(_on_message_edit_text_changed)
    send_button.disabled = true


func _on_send_button_pressed() -> void:
    var message = message_edit.text
    DeepSeekApi.chat(message)
    message_edit.text = ""
    send_button.disabled = true

    var l_message_label = MARKDOWN_LABEL_SCENE.instantiate()
    l_message_label.text = message
    l_message_label.is_sender = true
    messages_vbox.add_child(l_message_label)


func _on_message_received(message: String) -> void:
    # Logger.info("Message received: %s" % message)
    var l_message_label = MARKDOWN_LABEL_SCENE.instantiate()
    l_message_label.is_sender = false
    l_message_label.text = message
    messages_vbox.add_child(l_message_label)


# func _on_stream_data_received(data: String) -> void:
#     # Logger.info("Stream data received: %s" % data)
#     if message_box == null:
#         message_box = VBoxContainer.new()
#         message_box.add_theme_constant_override("separation", 0)
#         messages_vbox.add_child(message_box)

#     if data.find("[DONE]") != -1:
#         received_stream_content += data.replace("[DONE]", "")
#         Logger.info(received_stream_content)
#         var parser = Parser.new(received_stream_content)
#         parser.process()
#         var renderer = Renderer.new(parser.tokens)
#         renderer.render(message_box)

#         received_stream_content = ""
#         message_box = null
#     else:
#         received_stream_content += data
#         for child in message_box.get_children():
#             child.queue_free()
#         var parser = Parser.new(received_stream_content)
#         parser.process()
#         var renderer = Renderer.new(parser.tokens)
#         renderer.render(message_box)


func _on_stream_data_received(data: String) -> void:
    # Logger.info("Stream data received: %s" % data)
    if data == "[KEEP-ALIVE]":
        return

    if message_label == null:
        message_label = MARKDOWN_LABEL_SCENE.instantiate()
        message_label.is_sender = false
        messages_vbox.add_child(message_label)

    if data.find("[DONE]") != -1:
        received_stream_content += data.replace("[DONE]", "")
        # Logger.info(received_stream_content)
        message_label.set_content(received_stream_content)

        received_stream_content = ""
        message_label = null
    else:
        received_stream_content += data
        message_label.set_content(received_stream_content)


func _on_message_edit_text_changed() -> void:
    if message_edit.text.strip_edges() == "":
        send_button.disabled = true
    else:
        send_button.disabled = false
