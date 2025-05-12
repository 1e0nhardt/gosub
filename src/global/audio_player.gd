class_name AudioPlayer
extends Node

var player: AudioStreamPlayer = AudioStreamPlayer.new()
var bus_index: int = -1


func _init() -> void:
    # AudioServer.add_bus()
    # bus_index = AudioServer.bus_count - 1
    # player.bus = AudioServer.get_bus_name(bus_index)
    pass


func play(value: bool) -> void:
    player.stream_paused = !value


func play_at(from_position: float) -> void:
    player.play(from_position)


func stop() -> void:
    player.stop()


func is_playing() -> bool:
    return player.playing


func set_audio_stream(audio_stream: AudioStreamWAV) -> void:
    player.stream = audio_stream
    player.play()