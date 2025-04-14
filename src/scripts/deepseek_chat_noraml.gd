class_name DeepseekChatNormal
extends DeepseekChat

signal message_received(content: String)

var http_request: HTTPRequest


func _init(a_http_request: HTTPRequest) -> void:
    super._init()
    http_request = a_http_request
    http_request.request_completed.connect(_on_request_completed)


func send_message(message: String) -> void:
    add_user_message(message)
    # http_request.cancel_request()
    http_request.request(CHAT_COMPLETE_URL, deepseek_headers, HTTPClient.METHOD_POST, JSON.stringify(payload))


func send_message_without_history(message: String) -> void:
    var new_messages := [system_message_dict]
    new_messages.append({
        "role": "user",
        "content": message
    })
    payload_tmp["messages"] = new_messages
    http_request.request(CHAT_COMPLETE_URL, deepseek_headers, HTTPClient.METHOD_POST, JSON.stringify(payload_tmp))


func _on_request_completed(result, response_code, headers, body) -> void:
    if response_code == 200:
        var l_message := ""
        var response = JSON.parse_string(body.get_string_from_utf8())
        l_message = response["choices"][0].message.content
        add_assistant_message(l_message)
        message_received.emit(l_message)
    else:
        Logger.warn(result)
        Logger.warn(response_code)
        Logger.warn(headers)
