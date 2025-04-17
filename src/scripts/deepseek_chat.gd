class_name DeepseekChat
extends RefCounted

const DEEPSEEK_HOST = "https://api.deepseek.com"
const CHAT_COMPLETE_URL = "https://api.deepseek.com/chat/completions"
const AUTHORIZATION_HEADER = "Authorization: Bearer %s"

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

var system_message_dict := {
    "role": "system",
    "content": ProjectManager.get_setting_value("/llm/common/prompt/chat")
}
var messages := [system_message_dict.duplicate()]


func _init() -> void:
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
    messages = [system_message_dict.duplicate()]
    payload["messages"] = messages


func send_message(_message: String) -> void:
    pass


func send_message_without_history(_message: String) -> void:
    pass


func get_message() -> String:
    return "DeepseekChat: Should be implemented in child class."


func get_deepseek_api_key() -> String:
    var api_key = ProjectManager.get_setting_value("/llm/deepseek/api_key")
    if not api_key:
        Logger.warn("DeepseekChat: No API key found. Please set it in the project settings.")
        return ""

    return api_key.strip_edges()


func set_system_prompt(prompt: String) -> void:
    system_message_dict["content"] = prompt
    ProjectManager.set_setting_value("/llm/common/prompt/chat", prompt)
