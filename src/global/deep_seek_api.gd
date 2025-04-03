extends Node

signal message_received(content: String)

var deepseek_chat: DeepseekChat

@onready var http_request: HTTPRequest = $HTTPRequest


func _ready() -> void:
    deepseek_chat = DeepSeekChatStream.new()
    # deepseek_chat = DeepseekChatNormal.new(http_request)
    deepseek_chat.message_received.connect(func(c): message_received.emit(c))


func chat(message: String) -> void:
    deepseek_chat.send_message(message)


func chat_once(message: String) -> void:
    deepseek_chat.send_message_without_history(message)


func clear_history() -> void:
    deepseek_chat.clear_history_messages()


func poll() -> void:
    deepseek_chat.poll()