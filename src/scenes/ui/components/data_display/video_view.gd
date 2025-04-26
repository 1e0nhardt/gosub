@tool
class_name VideoView
extends HBoxContainer


var video_frames := []


func _draw() -> void:
    if video_frames.size() != 0:
        return

    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 1, 0))