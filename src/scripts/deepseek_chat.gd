class_name DeepseekChat
extends RefCounted

@warning_ignore("UNUSED_SIGNAL")
signal message_received(content: String)

const DEEPSEEK_HOST = "https://api.deepseek.com"
const CHAT_COMPLETE_URL = "https://api.deepseek.com/chat/completions"
const AUTHORIZATION_HEADER = "Authorization: Bearer %s"
const SYSTEM_MESSAGE = {
    "role": "system",
    "content": "You are a helpful assistant"
}

var messages := [SYSTEM_MESSAGE]
var payload := {
    "messages": [],
    "model": "deepseek-chat",
    "frequency_penalty": 0,
    "max_tokens": 8192,
    "presence_penalty": 0,
    "response_format": {
        "type": "text"
    },
    "stop": null,
    "stream": false,
    "stream_options": null,
    "temperature": 1,
    "top_p": 1,
    "tools": null,
    "tool_choice": "none",
    "logprobs": false,
    "top_logprobs": null
}
var payload_tmp := {}
var deepseek_headers := [
    "Content-Type: application/json",
    "Accept: application/json",
]


func _init() -> void:
    Logger.info("DeepseekChat initialized.")
    payload_tmp = payload.duplicate(true)
    payload["messages"] = messages
    deepseek_headers.append(AUTHORIZATION_HEADER % get_deepseek_api_key())


func add_user_message(message: String):
    messages.append({
        "role": "user",
        "content": message
    })


func add_assistant_message(message: String):
    messages.append({
        "role": "assistant",
        "content": message
    })


func clear_history_messages():
    messages = [SYSTEM_MESSAGE]
    payload["messages"] = messages


func send_message(_message: String) -> void:
    pass


func send_message_without_history(_message: String) -> void:
    pass


func get_message() -> String:
    return "DeepseekChat: Should be implemented in child class."


func get_deepseek_api_key() -> String:
    return "sk-4568478c989149daa5e6f4c9f8dcfa1d"
