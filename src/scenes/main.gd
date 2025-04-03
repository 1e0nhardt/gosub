extends Control

var is_playing: bool = false
var max_frame: int = 0
var raw_frame_rate: float = 0
var frame_rate: float = 0
var current_frame: int = 0:
    set(value):
        current_frame = value
        time_label.text = "%s/%s" % [
            Util.time_float2str(current_frame / raw_frame_rate),
            Util.time_float2str(max_frame / raw_frame_rate),
        ]
var current_time: float = 0:
    get:
        return current_frame / raw_frame_rate
var elapsed_time: float = 0
var frame_time: float:
    get:
        return 1.0 / frame_rate
var dragging = false
var video: Video = Video.new()

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var viewport: TextureRect = %Viewport
@onready var play_button: Button = %PlayButton
@onready var progress_slider: HSlider = %ProgressSlider
@onready var time_label: Label = %TimeLabel

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var messages_vbox: VBoxContainer = %MessagesVBox
@onready var message_edit: TextEdit = %MessageEdit
@onready var send_button: Button = %SendButton


func _ready() -> void:
    play_button.pressed.connect(_on_play_button_pressed)
    open_video(ProjectSettings.globalize_path("res://assets/test.mp4"))
    progress_slider.drag_started.connect(_on_progress_slider_drag_started)
    progress_slider.drag_ended.connect(_on_progress_slider_drag_ended)

    send_button.pressed.connect(_on_send_button_pressed)
    DeepSeekApi.message_received.connect(_on_message_received)


func _process(delta) -> void:
    DeepSeekApi.poll()

    if is_playing:
        elapsed_time += delta
        if elapsed_time < frame_time:
            return

        elapsed_time -= frame_time
        if !dragging:
            current_frame += 1

            if current_frame >= max_frame:
                is_playing = !is_playing
                video.seek_frame(1)
                current_frame = 1
                audio_stream_player.stream_paused = true
            else:
                viewport.texture.set_image(video.next_frame())

            progress_slider.value = current_frame


func open_video(filepath: String):
    if not filepath:
        return

    Logger.info("Video Path: %s" % filepath)

    video.open_video(filepath)
    audio_stream_player.stream = video.get_audio()
    max_frame = video.get_total_frame_number()
    raw_frame_rate = video.get_frame_rate()
    frame_rate = raw_frame_rate
    progress_slider.max_value = max_frame

    seek_frame(1)


func seek_frame(frame_number: int, flush_canvas = false):
    if flush_canvas:
        video.seek_frame(frame_number - 1)
        if frame_number <= max_frame:
            viewport.texture.set_image(video.next_frame())
    else:
        video.seek_frame(frame_number)
    current_frame = frame_number
    audio_stream_player.play(current_time)
    audio_stream_player.stream_paused = !is_playing
    progress_slider.set_value_no_signal(current_frame)


func seek_time(time: float, flush_canvas = false):
    seek_frame(int(time * raw_frame_rate), flush_canvas)


func play(flag: bool):
    is_playing = flag
    if is_playing:
        audio_stream_player.play(current_frame * frame_time)

    audio_stream_player.stream_paused = !is_playing


#region video player
func _on_play_button_pressed() -> void:
    Logger.info("Play button pressed")
    play(!is_playing)


func _on_progress_slider_drag_ended(_value_changed):
    dragging = false
    seek_frame(int(progress_slider.value))


func _on_progress_slider_drag_started():
    dragging = true
    audio_stream_player.stream_paused = true
#endregion


func _on_send_button_pressed() -> void:
    var message = message_edit.text
    DeepSeekApi.chat(message)
    message_edit.text = ""


func _on_message_received(message: String) -> void:
    Logger.info("Message received: %s" % message)
    var message_label = Label.new()
    message_label.text = message
    messages_vbox.add_child(message_label)