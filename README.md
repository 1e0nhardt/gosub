# Gosub

## 简介
Gosub 是使用 [Godot](https://github.com/godotengine/godot) 开发的双语字幕生成和编辑工具。

只需输入一个 youtube 视频链接，Gosub 就会自动下载视频，语音识别，生成字幕，翻译字幕，并让你轻松地观看视频，修正字幕。同时，内置了一个简单的 Deepseek Chat 界面，让你可以在遇到翻译问题时，找 Deepseek 聊天。

## 使用指南
### 设置 Deepseek API Key
在 [Deepseek 官网的API Key页面](https://platform.deepseek.com/api_keys)点击创建API Key。

将生成的API key复制到 Gosub 的设置中: llm->deepseek->api_key，接着按回车保存设置。

### 更换 Whisper 模型
- [Whisper.cpp 的模型下载页面](https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md)
- [ggml 模型地址](https://huggingface.co/ggerganov/whisper.cpp/tree/main)

下载完成后，修改设置: transcribe->whisper.cpp->model_path。

## 致谢
- Youtube 视频下载: [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- 语音识别: [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
- 音频提取，视频播放，视频渲染: [ffmpeg](https://github.com/FFmpeg/FFmpeg)
- 视频播放: [VoylinsGamedevJourney/gde_gozen](https://github.com/VoylinsGamedevJourney/gde_gozen)
