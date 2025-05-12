extends Node


func create_audio_player() -> AudioPlayer:
    var player = AudioPlayer.new()
    add_child(player.player)
    return player
