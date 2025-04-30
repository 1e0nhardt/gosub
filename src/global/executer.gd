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
    var proxy = ProjectManager.get_setting_value("/video/download/proxy")
    var args := ""
    if proxy:
        args = '--proxy http://127.0.0.1:7890 --get-title "%s"' % url
    else:
        args = '--get-title "%s"' % url

    var executer_helper = ExecuterHelper.new(yt_dlp_path)
    executer_helper.set_args(args)
    executer_helper.execute_with_pipe()
    Logger.info(executer_helper.stdio_output)
    return executer_helper.stdio_output


## 使用 yt-dlp 下载音频 [br]
## [param url] 视频链接
## [param output_dir] 输出目录
static func download_video(url: String, output_path: String = "") -> bool:
    if FileAccess.file_exists(output_path):
        return true

    var result = download_video_execute_prepare(url, output_path)
    var executer_helper = ExecuterHelper.new(result[0])
    executer_helper.set_args(result[1])
    return executer_helper.execute()


static func download_video_execute_prepare(url: String, output_path: String = "") -> Array[String]:
    var yt_dlp_path = get_real_path("bin/yt-dlp.exe")
    var args = ""
    var proxy = ProjectManager.get_setting_value("/video/download/proxy")
    if proxy:
        args += '-o "%s" --proxy %s --write-thumbnail --convert-thumbnails png -f "bestvideo[height<=1080][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]" --merge-output-format mp4 "%s"' % [output_path, proxy, url]
    else:
        args += '-o "%s" --write-thumbnail --convert-thumbnails png -f "bestvideo[height<=1080][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]" --merge-output-format mp4 "%s"' % [output_path, url]
    return [yt_dlp_path, args]


## 使用 ffmpeg 提取 wav 音频 [br]
## [param video_file_path] 视频文件绝对路径 [br]
## [param output_dir] 输出目录
static func extract_audio(video_file_path: String, output_path: String = "") -> bool:
    if output_path == "":
        output_path = video_file_path.get_basename() + ".wav"

    if FileAccess.file_exists(output_path):
        return true

    var result = extract_audio_execute_prepare(video_file_path, output_path)
    var executer_helper = ExecuterHelper.new(result[0])
    executer_helper.set_args(result[1])
    return executer_helper.execute()


static func extract_audio_execute_prepare(video_file_path: String, output_path: String = "", override := true) -> Array[String]:
    var ffmpeg_path = get_real_path("bin/ffmpeg.exe")
    var args := '-i "%s" -ar 16000 -ac 1 -c:a pcm_s16le "%s"' % [video_file_path, output_path]
    if override:
        args += " -y"
    return [ffmpeg_path, args]


## 使用 whisper.cpp 转录音频  [br]
## [param audio_file_path] 音频文件绝对路径
static func transcribe_audio(audio_file_path: String, output_path: String = "") -> bool:
    if output_path == "":
        output_path = audio_file_path.get_basename() + ".json"

    if FileAccess.file_exists(output_path):
        return true

    var result = transcribe_audio_execute_prepare(audio_file_path, output_path)
    var executer_helper = ExecuterHelper.new(result[0])
    executer_helper.set_args(result[1])
    return executer_helper.execute()


static func transcribe_audio_execute_prepare(audio_file_path: String, output_path: String = "") -> Array[String]:
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
    return [whisper_cli_path, args]


## 使用 whisper.cpp 转录音频片段  [br]
## [param audio_file_path] 音频文件绝对路径
## [param offset_from] 开始时间
## [param offset_to] 结束时间
static func transcribe_segment(audio_file_path: String, offset_from: int, offset_to: int) -> bool:
    var result = transcribe_segment_execute_prepare(audio_file_path, offset_from, offset_to)
    var executer_helper = ExecuterHelper.new(result[0])
    executer_helper.set_args(result[1])
    return executer_helper.execute()


static func transcribe_segment_execute_prepare(audio_file_path: String, offset_from: int, offset_to: int) -> Array[String]:
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
    return [whisper_cli_path, args]


static func render_video_with_hard_subtitles(video_file_path: String, subtitles_path: String, output_path: String = "", bit_rate: String = "6M") -> bool:
    if FileAccess.file_exists(output_path):
        return true

    if not FileAccess.file_exists(subtitles_path):
        Logger.info("Subtitle file not exists!")
        return false

    var result = render_video_with_hard_subtitles_execute_prepare(video_file_path, subtitles_path, output_path, bit_rate)
    var executer_helper = ExecuterHelper.new(result[0])
    executer_helper.set_args(result[1])
    return executer_helper.execute()


static func render_video_with_hard_subtitles_execute_prepare(video_file_path: String, subtitles_path: String, output_path: String = "", bit_rate: String = "6M") -> Array[String]:
    var ffmpeg_path = get_real_path("bin/ffmpeg.exe")
    # 滤镜参数中 `:` 是特殊字符，需要转义，否则会报错
    subtitles_path = subtitles_path.replace(":", "\\:")
    var args = '-i "%s" -vf "subtitles=\'%s\'" -b:v %s "%s"' % [video_file_path, subtitles_path, bit_rate, output_path]
    return [ffmpeg_path, args]


## 辅助类
class ExecuterHelper extends RefCounted:
    var _executable_path: String = ""
    var _args: PackedStringArray = []

    var exit_code = -1;
    var error_msg = []
    var stdio_output = ""

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

    func get_file_output(file: FileAccess) -> String:
        var result := ""
        while file.is_open():
            var line = file.get_line()
            var should_break := false
            if line.strip_edges() == "":
                var amount: int = 0
                while amount < 2: # 至少连续三次输出空行才算结束
                    line = file.get_line()
                    if line.strip_edges() != "":
                        should_break = false
                        break
                    amount += 1
                if amount >= 2:
                    should_break = true

            if should_break:
                break

            while line:
                result += line + "\n"
                line = file.get_line()

        return result

    # 阻塞执行，在程序运行时退出会导致卡顿
    func execute() -> bool:
        exit_code = -1;
        error_msg = []

        exit_code = OS.execute(_executable_path, _args, error_msg, true)

        if exit_code != 0:
            # print_rich("[red] %s" % error_msg[0])
            print(error_msg)
            return false

        return true

    # 执行外部程序，并获取命令行输出
    func execute_with_pipe() -> bool:
        var dict := OS.execute_with_pipe(_executable_path, _args, true)
        var pid = dict["pid"]
        TaskThreadPool.running_pid.append(pid)
        stdio_output = get_file_output(dict["stdio"])
        TaskThreadPool.running_pid.erase(pid)
        return true

    # 创建子进程，非阻塞，可以用 kill 强制结束
    func create_process() -> int:
        return OS.create_process(_executable_path, _args)
