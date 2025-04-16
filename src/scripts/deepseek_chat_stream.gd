class_name DeepSeekChatStream
extends DeepseekChat

signal stream_data_received(message: String)

var http_client: HTTPClient


func _init() -> void:
    super._init()
    payload["stream"] = true
    payload_tmp["stream"] = true
    http_client = HTTPClient.new()
    var err = http_client.connect_to_host(DEEPSEEK_HOST)
    if err != OK:
        Logger.error("Failed to connect to DeepSeek server")
        return

    # Wait until resolved and connected.
    while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
        http_client.poll()
        # Logger.info("Connecting...")

    if http_client.get_status() != HTTPClient.STATUS_CONNECTED: # Check if the connection was made successfully.
        Logger.error("Connection failed")
        return


func send_message(message: String) -> void:
    add_user_message(message)
    http_client.request(HTTPClient.METHOD_POST, CHAT_COMPLETE_URL, deepseek_headers, JSON.stringify(payload))


func send_message_without_history(message: String) -> void:
    var new_messages := [system_message_dict.duplicate()]
    new_messages.append({
        "role": "user",
        "content": message
    })
    payload_tmp["messages"] = new_messages
    http_client.request(HTTPClient.METHOD_POST, CHAT_COMPLETE_URL, deepseek_headers, JSON.stringify(payload_tmp))


func get_message_from_stream_data(stream_data: String) -> String:
    var message = ""
    var data = stream_data.split("\n", false)
    # Logger.info(data)
    var json: Dictionary
    for line: String in data:
        if line.find("[DONE]") != -1:
            message += "[DONE]"
            continue
        line = line.split(":", false, 1)[1]
        json = JSON.parse_string(line)
        if not json:
            return "[ERR]"
        if json.has("choices") and json["choices"][0].has("delta"):
            message += json["choices"][0]["delta"]["content"]
    return message


func poll() -> void:
    while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
        # Keep polling for as long as the request is being processed.
        http_client.poll()
        # Logger.info("Requesting...")

    if http_client.get_status() == HTTPClient.STATUS_BODY or http_client.get_status() == HTTPClient.STATUS_CONNECTED:
        if http_client.has_response():
            # var headers = http_client.get_response_headers_as_dictionary() # Get response headers.
            # Logger.info("code: %d" % http_client.get_response_code()) # Show response code.
            # Logger.info(headers) # Show headers.
            if http_client.is_response_chunked():
                # Does it use chunks?
                # Logger.info("Response is Chunked!")
                pass
            else:
                # Or just plain Content-Length
                var bl = http_client.get_response_body_length()
                Logger.info("Response Length: %d" % bl)

            # This method works for both anyway
            # var rb = PackedByteArray() # Array that will hold the data.

            while http_client.get_status() == HTTPClient.STATUS_BODY:
                # While there is body left to be read
                http_client.poll()
                # Get a chunk.
                var chunk = http_client.read_response_body_chunk()
                if chunk.size() == 0:
                    continue
                else:
                    # stream_data_received.emit(chunk.get_string_from_utf8())
                    stream_data_received.emit(get_message_from_stream_data(chunk.get_string_from_utf8()))
                    # rb = rb + chunk # Append to read buffer.
                # Logger.info(chunk.get_string_from_utf8())
            # Done!

            # Logger.info("bytes got: %d" % rb.size())
            # var text = rb.get_string_from_utf8()
            # Logger.info("Text: %s" % text)
