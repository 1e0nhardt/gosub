class_name WaveformView
extends Control

var waveform_color: Color
var waveform: Waveform


func _ready():
    resized.connect(_on_resized)
    waveform_color = get_theme_color("waveform_color", "Main")
    waveform = Waveform.new(self, waveform_color)


func _draw():
    waveform.draw()


func set_stream(a_audio_stream: AudioStreamWAV):
    waveform.set_stream(a_audio_stream)


func _on_resized() -> void:
    waveform.calculate_envelope()


class Waveform extends RefCounted:
    var audio_data: PackedByteArray
    var audio_stream: AudioStreamWAV
    var pos_envelope := []
    var neg_envelope := []
    var canvas_node: Control
    var color: Color
    var block_spacing: int = 4
    var width: float
    var dirty: bool = false
    var calculate_envelope_task: StatedTask

    func _init(node: Control, a_color: Color = Color.WHITE):
        canvas_node = node
        color = a_color
        dirty = true

    func set_stream(a_audio_stream: AudioStreamWAV):
        audio_stream = a_audio_stream
        audio_data = audio_stream.data
        calculate_envelope()
        canvas_node.queue_redraw()

    func set_waveform_width(a_width: float):
        width = a_width
        canvas_node.queue_redraw()

    func calculate_envelope() -> void:
        if not dirty:
            return

        if calculate_envelope_task and (not calculate_envelope_task.is_completed()):
            return

        var frames_per_block = ceili(_calc_total_frames(audio_data) / canvas_node.size.x) * block_spacing
        calculate_envelope_task = StatedTask.new(calculate_envelope_thread.bind(audio_data, frames_per_block), calculate_envelope_thread_callback)
        TaskThreadPool.add_task(calculate_envelope_task)

    func calculate_envelope_thread(state: Dictionary, a_audio_data: PackedByteArray, frames_per_block: int) -> void:
        var ret = Util.calculate_audio_wave_envelope(a_audio_data, frames_per_block)
        state["pos_envelope"] = ret[0]
        state["neg_envelope"] = ret[1]

    func calculate_envelope_thread_callback(state: Dictionary) -> void:
        pos_envelope = state["pos_envelope"]
        neg_envelope = state["neg_envelope"]
        dirty = false
        canvas_node.queue_redraw()

    func draw() -> void:
        var block_amount: int = pos_envelope.size()
        if block_amount == 0:
            return

        if block_amount != neg_envelope.size():
            return

        var w: float = width / block_amount
        var half_height = canvas_node.size.y / 2
        for i in range(block_amount):
            var pos_h: float = half_height * pos_envelope[i]
            var neg_h: float = half_height * abs(neg_envelope[i])
            canvas_node.draw_line(Vector2(i * w, half_height), Vector2(i * w, half_height - pos_h), color, max(w / block_spacing, 1.0))
            canvas_node.draw_line(Vector2(i * w, half_height), Vector2(i * w, half_height + neg_h), color, max(w / block_spacing, 1.0))

    func _calc_total_frames(data: PackedByteArray) -> int:
        return ceili(data.size() / 4.0)