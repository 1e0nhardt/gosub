class_name Constant
extends Object

# Prompt
const DEFAULT_PROMPT = "You are a helpful assistant"
const GOSUB_TRANSLATE = """请你扮演专业翻译员的角色。将各种语言的输入翻译为中文。翻译时追求自然流畅、贴近原文。

**注意事项**：
- 严格保留每行开头的时间格式，示例"[1.44->3.18]"。
- 翻译结果不要换行，不要省略标点符号。
- 不要输出任何与翻译结果无关的注释内容。

**翻译示例**：
输入：
[00:03:44.060->00:03:45.720]So let's open up the project,

输出：
[00:03:44.060->00:03:45.720]让我们打开项目，
"""

const ASS_TEMPLATE = """[Script Info]
; Script generated by Gosub
; https://github.com/1e0nhardt/Gosub
ScriptType: v4.00+
ScaledBorderAndShadow: Yes
PlayResX: 1920
PlayResY: 1080
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: EN,Resource Han Rounded CN Regular,40,&H00FFFFFF,&HF0000000,&H00000000,&H32000000,0,0,0,0,100,100,0,0,1,2,1,2,5,5,15,1
Style: ZH,Resource Han Rounded CN Regular,64,&H00FFFFFF,&HF00000FF,&H00000000,&H32000000,-1,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

const DEFAULT_SETTINGS := {
    "video": {
        "download": {
            "proxy": {
                "type": TYPE_STRING,
                "data": "http://127.0.0.1:7890",
                "tooltip": "Proxy for downloading video."
            },
        },
        "render": {
            "bit_rate": {
                "type": TYPE_STRING,
                "data": "6M",
                "tooltip": "Bit rate for video encoding."
            },
        },
    },
    "transcribe": {
        "whisper.cpp": {
            "model_path": {
                "type": TYPE_STRING,
                "data": "ggml-deepseek-medium.bin",
                "tooltip": "Path to the model file.",
            },
        },
    },
    "llm": {
        "deepseek": {
            "api_key": {
                "type": TYPE_STRING,
                "data": "",
                "tooltip": "API key for DeepSeek.",
            },
            "prompt": {
                "translate": {
                    "type": TYPE_STRING,
                    "data": GOSUB_TRANSLATE,
                    "tooltip": "Translate prompt for DeepSeek.",
                },
                "chat": {
                    "type": TYPE_STRING,
                    "data": DEFAULT_PROMPT,
                    "tooltip": "Chat prompt for DeepSeek.",
                }
            },
        },
    },
    "subtitle": {
        "ass": {
            "template": {
                "type": TYPE_STRING,
                "data": ASS_TEMPLATE,
                "tooltip": "Template for ASS subtitle.",
            }
        },
    },
}
