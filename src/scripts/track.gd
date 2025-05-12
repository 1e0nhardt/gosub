class_name Track
extends RefCounted

enum SHADER_ID {EMPTY, YUV, YUV_FULL, IMAGE}

var canvas_texture: TextureRect
var canvas_material: ShaderMaterial:
    get(): return canvas_texture.material if canvas_texture else null
var video: Video
var audio_player: AudioPlayer
var shader_id = SHADER_ID.EMPTY
var color_correction_enabled = false
var color_profile: Vector4 = Vector4(1.0, 1.0, 1.0, 1.0)

var y_texture: ImageTexture
var u_texture: ImageTexture
var v_texture: ImageTexture


func _init() -> void:
    canvas_texture = TextureRect.new()
    canvas_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    canvas_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    canvas_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas_texture.material = ShaderMaterial.new()
    audio_player = AudioManager.create_audio_player()
    canvas_texture.texture = PlaceholderTexture2D.new()


func open_video(a_video_path: String) -> void:
    if not FileAccess.file_exists(a_video_path):
        Logger.error("File not found: %s" % a_video_path)
        return

    video = Video.new()
    video.open(a_video_path)
    set_video(video)


func set_video(a_video: Video) -> void:
    video = a_video
    canvas_texture.texture.size = video.get_resolution()

    match a_video.get_color_space_name():
        "bt601", "bt470": color_profile = Vector4(1.402, 0.344136, 0.714136, 1.772)
        "bt2020", "bt2100": color_profile = Vector4(1.4746, 0.16455, 0.57135, 1.8814)
        _: # bt709 and unknown
            color_profile = Vector4(1.5748, 0.1873, 0.4681, 1.8556)

    if video.get_is_full_color_range():
        shader_id = SHADER_ID.YUV_FULL
        canvas_material.shader = preload("res://shaders/yuv420p_full.gdshader")
    else:
        shader_id = SHADER_ID.YUV
        canvas_material.shader = preload("res://shaders/yuv420p_standard.gdshader")

    y_texture = ImageTexture.create_from_image(video.get_y_data())
    u_texture = ImageTexture.create_from_image(video.get_u_data())
    v_texture = ImageTexture.create_from_image(video.get_v_data())

    canvas_material.set_shader_parameter("y_data", y_texture)
    canvas_material.set_shader_parameter("u_data", u_texture)
    canvas_material.set_shader_parameter("v_data", v_texture)


func set_audio(a_audio_steam) -> void:
    audio_player.set_audio_stream(a_audio_steam)


func update_frame(frame_number: int) -> void:
    # seek_frame(frame_number)
    if not video.next_frame(false):
        Logger.warn("Failed to read frame %s" % frame_number)
    update_canvas()
    # var t = frame_number / video.get_framerate()
    # audio_player.play_at(t)


func seek_frame(frame_number: int):
    if frame_number < 0 or frame_number >= video.get_frame_count():
        Logger.info("Invalid frame number: %s" % frame_number)
        return

    if not video.seek_frame(frame_number):
        Logger.warn("Failed to seek to frame %s" % frame_number)

    update_canvas()

    var t = frame_number / video.get_framerate()
    audio_player.play_at(t)


func update_canvas():
    if video:
        y_texture.update(video.get_y_data())
        u_texture.update(video.get_u_data())
        v_texture.update(video.get_v_data())

        if canvas_material.get_shader_parameter("resolution") != Vector2(video.get_resolution()):
            canvas_material.set_shader_parameter("resolution", video.get_resolution() as Vector2)
        if canvas_material.get_shader_parameter("color_profile") != color_profile:
            Logger.info(color_profile)
            canvas_material.set_shader_parameter("color_profile", color_profile)
