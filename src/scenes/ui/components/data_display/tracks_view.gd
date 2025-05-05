class_name TracksView
extends VBoxContainer

const WAVEFORM_VIEW = preload("res://scenes/ui/components/data_display/waveform_view.tscn")

var audio_stream: AudioStreamWAV
var waveform_view_instance: WaveformView
var max_audio_waveform_width: float = 0:
    set(value):
        max_audio_waveform_width = value
        if waveform_view_instance:
            waveform_view_instance.waveform.set_waveform_width(value)


func set_audio_stream(a_audio_stream: AudioStream) -> void:
    audio_stream = a_audio_stream
    if not waveform_view_instance:
        waveform_view_instance = WAVEFORM_VIEW.instantiate()
        add_child(waveform_view_instance)

    waveform_view_instance.set_stream(audio_stream)


func mark_waveform_dirty() -> void:
    if waveform_view_instance:
        waveform_view_instance.waveform.dirty = true