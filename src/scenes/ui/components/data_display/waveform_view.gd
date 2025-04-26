@tool
class_name WaveformView
extends Control

const TEST_WAV_PATH := "res://assets/test_sounds/debussy.wav"

@export var block_spacing: int = 4

var audio_data: PackedByteArray
var pos_envelope := []
var neg_envelope := []

var waveform_color: Color


func _ready():
    # audio_data = AudioStreamWAV.load_from_file(TEST_WAV_PATH).data
    audio_data = []

    resized.connect(_on_resized)

    waveform_color = get_theme_color("waveform_color", "Main")


func _draw():
    var block_amount: int = pos_envelope.size()
    if block_amount == 0:
        return

    if block_amount != neg_envelope.size():
        return

    var w: float = size.x / block_amount
    var half_height = size.y / 2
    for i in range(block_amount):
        var pos_h: float = half_height * pos_envelope[i]
        var neg_h: float = half_height * abs(neg_envelope[i])
        draw_line(Vector2(i * w, half_height), Vector2(i * w, half_height - pos_h), waveform_color, max(w / block_spacing, 1.0))
        draw_line(Vector2(i * w, half_height), Vector2(i * w, half_height + neg_h), waveform_color, max(w / block_spacing, 1.0))


func _on_resized() -> void:
    var ret = Util.calculate_audio_wave_envelope(audio_data, ceili(_calc_total_frames(audio_data) / size.x) * block_spacing)
    pos_envelope = ret[0]
    neg_envelope = ret[1]
    queue_redraw()


func _calc_total_frames(data: PackedByteArray) -> int:
    return ceili(data.size() / 4.0)