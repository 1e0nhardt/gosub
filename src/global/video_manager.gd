extends Node

const TRACK_AMOUNT = 1

var viewport: SubViewport
var tracks: Array[Track] = []

var is_playing: bool = false
var frame_nr: int = 0
var time_elapsed: float = 0.0
var frame_time: float = 1.0 / 30.0 # Get's set when changing framerate
var skips: int = 0

var frame_rate: int
var frame_count: int


func process(delta: float) -> void:
    if !is_playing:
        return

    skips = 0
    time_elapsed += delta

    if time_elapsed < frame_time:
        return

    while time_elapsed >= frame_time:
        time_elapsed -= frame_time
        skips += 1

    frame_nr += skips
    set_frame(frame_nr)


func open_video(video_path: String) -> void:
    if not FileAccess.file_exists(video_path):
        return

    VideoManager.tracks[0].open_video(video_path)
    frame_rate = int(VideoManager.tracks[0].video.get_framerate())
    frame_count = VideoManager.tracks[0].video.get_frame_count()
    var audio_stream := _load_audio_data(video_path.replace(".mp4", ".wav"))
    VideoManager.tracks[0].audio_player.set_audio_stream(audio_stream)
    play(false)
    EventBus.audio_loaded.emit(audio_stream)


func _load_audio_data(file_path: String) -> AudioStreamWAV:
    if FileAccess.file_exists(file_path.get_basename() + ".wav"):
        return AudioStreamWAV.load_from_file(file_path.get_basename() + ".wav")

    var audio_data: PackedByteArray = Audio.get_audio_data(file_path)

    if audio_data.size() == 0:
        return

    var audio = AudioStreamWAV.new()
    audio.mix_rate = 44100
    audio.stereo = true
    audio.format = AudioStreamWAV.FORMAT_16_BITS
    audio.data = audio_data
    return audio


func set_frame(frame_number: int = frame_nr + 1) -> void:
    if frame_nr != frame_number:
        frame_nr = frame_number

    for track: Track in tracks:
        track.update_frame(frame_number)

    # if frame_nr >= frame_count:
        # is_playing = false


func seek_frame(frame_number: int) -> void:
    frame_nr = frame_number
    for track: Track in tracks:
        track.seek_frame(frame_number)


func setup_playback() -> void:
    viewport.size = Vector2i(1920, 1080)

    for i: int in TRACK_AMOUNT:
        var track := Track.new()
        tracks.append(track)
        viewport.add_child(track.canvas_texture)
        viewport.move_child(track.canvas_texture, 1)


func play(flag: bool = true) -> void:
    is_playing = flag
    VideoManager.tracks[0].audio_player.play(flag)


func get_time_label_text() -> String:
    return "%s/%s" % [
            Util.time_float2str(frame_nr / float(frame_rate)),
            Util.time_float2str(frame_count / float(frame_rate)),
        ]


func get_current_time() -> float:
    return frame_nr / float(frame_rate)


func render() -> void:
    Profiler.start("VideoManager.render")
    var renderer = Renderer.new()
    renderer.enable_debug()

    var output_file_path: String = ProjectManager.current_project.output_video_title + "_output.mp4"
    renderer.set_file_path(output_file_path)
    renderer.set_resolution(tracks[0].video.get_resolution())
    Logger.info(output_file_path)
    Logger.info(tracks[0].video.get_resolution())
    renderer.set_audio_codec_id(Renderer.AUDIO_CODEC.A_NONE)
    renderer.set_video_codec_id(Renderer.VIDEO_CODEC.V_H264)
    renderer.set_gop_size(15)
    renderer.set_crf(20) # Slider has a negative value
    renderer.set_sws_quality(Renderer.SWS_QUALITY_BILINEAR)

    # video_codec_id == 27
    renderer.set_h264_preset(Renderer.H264_PRESETS.H264_PRESET_FAST)

    var title: String = ProjectManager.current_project.output_video_title
    var comment: String = "some comment"
    var author: String = "1e0nhardt"
    var copyright: String = "copyright 2025"

    if title != "":
        renderer.set_video_meta_title(title)
    if comment != "":
        renderer.set_video_meta_comment(comment)
    if author != "":
        renderer.set_video_meta_author(author)
    if copyright != "":
        renderer.set_video_meta_copyright(copyright)

    if !renderer.open():
        Logger.error("Something went wrong and rendering isn't possible!")
        return

    set_frame(0)
    for i in range(frame_count):
        await RenderingServer.frame_post_draw

        if !renderer.send_frame(viewport.get_image()):
            Logger.error("Something went wrong sending frame!")
        set_frame()

    renderer.close()
    Profiler.stop("VideoManager.render")