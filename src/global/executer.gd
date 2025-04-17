class_name Executer
extends Object


## 将相对路径转换成绝对路径 [br]
## [param path] 相对路径
static func get_real_path(rel_path: String) -> String:
    if OS.has_feature("editor"):
        rel_path = ProjectSettings.globalize_path("res://%s" % rel_path)
    else:
        rel_path = OS.get_executable_path().get_base_dir().path_join(rel_path)
    return rel_path


## 获取视频标题
## [param url] 视频链接
static func get_video_title(url: String) -> String:
    var yt_dlp_path = get_real_path("bin/yt-dlp.exe")
    var args = '--proxy http://127.0.0.1:7890 --get-title "%s"' % url
    var executer_helper = ExecuterHelper.new(yt_dlp_path)
    executer_helper.set_args(args)
    executer_helper.execute()
    return executer_helper.error_msg[0] if executer_helper.exit_code == 0 else ""


## 使用 yt-dlp 下载音频 [br]
## [param url] 视频链接
## [param output_dir] 输出目录
static func download_video(url: String, output_path: String = "") -> bool:
    if FileAccess.file_exists(output_path):
        return true

    var yt_dlp_path = get_real_path("bin/yt-dlp.exe")

    var args = ""
    var proxy = ProjectManager.get_setting_value("/video/download/proxy")
    if proxy:
        args += '-o "%s" --proxy %s --write-thumbnail --convert-thumbnails png -f "bestvideo[height<=1080][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]" --merge-output-format mp4 "%s"' % [output_path, proxy, url]
    else:
        args += '-o "%s" --write-thumbnail --convert-thumbnails png -f "bestvideo[height<=1080][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]" --merge-output-format mp4 "%s"' % [output_path, url]
    var executer_helper = ExecuterHelper.new(yt_dlp_path)
    executer_helper.set_args(args)
    return executer_helper.execute()


## 使用 ffmpeg 提取 wav 音频 [br]
## [param video_file_path] 视频文件绝对路径 [br]
## [param output_dir] 输出目录
static func extract_audio(video_file_path: String, output_path: String = "") -> bool:
    if FileAccess.file_exists(output_path):
        return true

    var ffmpeg_path = get_real_path("bin/ffmpeg.exe")
    var args = '-i "%s" -ar 16000 -ac 1 -c:a pcm_s16le "%s"' % [video_file_path, output_path]
    var executer_helper = ExecuterHelper.new(ffmpeg_path)
    executer_helper.set_args(args)
    return executer_helper.execute()


## 使用 whisper.cpp 转录音频  [br]
## [param audio_file_path] 音频文件绝对路径
static func transcribe_audio(audio_file_path: String, output_path: String = "") -> bool:
    # if FileAccess.file_exists(output_path):
    #     return true

    var whisper_cli_path = get_real_path("bin/whisper/cuda/whisper-cli.exe")
    if not ProjectManager.get_setting_value("/transcribe/whisper.cpp/use_gpu"):
        whisper_cli_path = get_real_path("bin/whisper/cpu/whisper-cli.exe")

    var model_path = ProjectManager.get_setting_value("/transcribe/whisper.cpp/model_path")
    if not model_path:
        model_path = get_real_path("bin/whisper/models/ggml-base.en.bin")

    var args = '-m "%s" -f "%s" -of "%s" --output-json --split-on-word' % [
        model_path,
        audio_file_path,
        output_path.get_basename()
    ]
    var smart = ProjectManager.get_setting_value("/transcribe/whisper.cpp/smart_split")
    if smart:
        args += " -ml 1"
    var executer_helper = ExecuterHelper.new(whisper_cli_path)
    executer_helper.set_args(args)
    return executer_helper.execute()


## 使用 whisper.cpp 转录音频片段  [br]
## [param audio_file_path] 音频文件绝对路径
## [param offset_from] 开始时间
## [param offset_to] 结束时间
static func transcribe_segment(audio_file_path: String, offset_from: int, offset_to: int) -> bool:
    var whisper_cli_path = get_real_path("bin/whisper/cuda/whisper-cli.exe")
    if not ProjectManager.get_setting_value("/transcribe/whisper.cpp/use_gpu"):
        whisper_cli_path = get_real_path("bin/whisper/cpu/whisper-cli.exe")

    var model_path = ProjectManager.get_setting_value("/transcribe/whisper.cpp/model_path")
    if not model_path:
        model_path = get_real_path("bin/whisper/models/ggml-base.en.bin")

    var args = '-m "%s" -f "%s" -of "%s" -ot %d -d %d --output-json --split-on-word' % [
        model_path,
        audio_file_path,
        audio_file_path.get_base_dir().path_join("temp_segment"),
        offset_from,
        offset_to - offset_from
    ]
    var smart = ProjectManager.get_setting_value("/transcribe/whisper.cpp/smart_split")
    if smart:
        args += " -ml 1"
    var executer_helper = ExecuterHelper.new(whisper_cli_path)
    executer_helper.set_args(args)
    return executer_helper.execute()


static func render_video_with_hard_subtitles(video_file_path: String, subtitles_path: String, output_path: String = "", bit_rate: String = "6M") -> bool:
    if FileAccess.file_exists(output_path):
        return true

    if not FileAccess.file_exists(subtitles_path):
        Logger.info("Subtitle file not exists!")
        return false

    var ffmpeg_path = get_real_path("bin/ffmpeg.exe")
    # 滤镜参数中 `:` 是特殊字符，需要转义，否则会报错
    subtitles_path = subtitles_path.replace(":", "\\:")

    var args = '-i "%s" -vf "subtitles=\'%s\'" -b:v %s "%s"' % [video_file_path, subtitles_path, bit_rate, output_path]
    Logger.info(args)
    var executer_helper = ExecuterHelper.new(ffmpeg_path)
    executer_helper.set_args(args)
    return executer_helper.execute()


## 辅助类
class ExecuterHelper extends RefCounted:
    var _executable_path: String = ""
    var _args: PackedStringArray = []

    var exit_code = -1;
    var error_msg = []

    func _init(executable_path: String):
        _executable_path = executable_path

    func set_args(args: String) -> void:
        _args = arguments_to_array(args)
        # print(_args)

    func arguments_to_array(args_str: String) -> PackedStringArray:
        var args_array := []
        var index = 0
        var cur_split = ""
        var total_length := args_str.length()
        while index < total_length:
            while args_str[index] == " ":
                index += 1

            if index >= total_length:
                break

            # 支持 "test file.wav" 这种参数
            if args_str[index] == "\"":
                # cur_split += args_str[index]
                index += 1
                while index < total_length and args_str[index] != "\"":
                    cur_split += args_str[index]
                    index += 1
                # 遇到`"`退出
                if args_str[index] == "\"":
                    # cur_split += args_str[index]
                    index += 1
            else:
                cur_split += args_str[index]
                index += 1
                while index < total_length and args_str[index] != " ":
                    cur_split += args_str[index]
                    index += 1
            args_array.append(cur_split)
            cur_split = ""

        return PackedStringArray(args_array)

    func execute() -> bool:
        exit_code = -1;
        error_msg = []

        exit_code = OS.execute(_executable_path, _args, error_msg, true)

        if exit_code != 0:
            # print_rich("[red] %s" % error_msg[0])
            print(error_msg)
            return false

        return true
