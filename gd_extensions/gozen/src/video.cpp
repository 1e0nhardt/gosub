#include "Video.hpp"

#include <iostream>
#include <chrono>

class Timer
{
public:
    Timer()
    {
        start_time = std::chrono::high_resolution_clock::now();
    }

    void stop()
    {
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time).count();
        UtilityFunctions::print("Time taken: ", duration, " microseconds");
    }

private:
    std::chrono::high_resolution_clock::time_point start_time;
};

void cprintf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    char buf[1024];
    vsprintf(buf, fmt, args);
    va_end(args);
    godot::String output = "[color=green]" + godot::String(buf);
    UtilityFunctions::print_rich(output);
}

void Video::open_video(String a_text)
{
    UtilityFunctions::print(a_text);

    // 为 AVFormatContext 分配内存，利用它可以获得相关格式（容器）的信息
    av_format_ctx = avformat_alloc_context();
    if (!av_format_ctx)
    {
        UtilityFunctions::printerr("Error allocating format context");
        return;
    }

    // 打开文件并读取文件的头信息，利用相关格式的简要信息填充 AVFormatContext（注意，编解码器通常不会被打开）
    if (avformat_open_input(&av_format_ctx, a_text.utf8().get_data(), NULL, NULL) != 0)
    {
        UtilityFunctions::printerr("Error opening video file!");
        close_video();
        return;
    }

    // 可以输出视频的格式和时长
    cprintf("Format: %s, duration: %lld us", av_format_ctx->iformat->long_name, av_format_ctx->duration);

    // 从媒体文件中读取数据。需要利用函数 avformat_find_stream_info完成此步骤。av_format_ctx->nb_streams 将获取所有的流的数量，并且通过 av_format_ctx->streams[i] 获取到指定的 i 数据流。
    if (avformat_find_stream_info(av_format_ctx, NULL) < 0)
    {
        UtilityFunctions::printerr("Couldn't find stream information");
        close_video();
        return;
    }

    // 使用循环来获取所有流数据
    for (int i = 0; i < av_format_ctx->nb_streams; i++)
    {
        // 每个流维护一个对应的 AVCodecParameters，该结构体描述了被编码流的各种属性
        AVCodecParameters *av_codec_params = av_format_ctx->streams[i]->codecpar;

        const AVCodec *pLocalCodec = avcodec_find_decoder(av_codec_params->codec_id);

        if (avcodec_find_decoder(av_codec_params->codec_id) == NULL)
        {
            continue;
        }
        else if (av_codec_params->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            av_stream_video = av_format_ctx->streams[i];
        }
        else if (av_codec_params->codec_type == AVMEDIA_TYPE_AUDIO)
        {
            av_stream_audio = av_format_ctx->streams[i];
        }

        // 编解码信息
        // 用于视频和音频
        if (av_codec_params->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            cprintf("Video Codec: resolution: %d x %d", av_codec_params->width, av_codec_params->height);
        }
        else if (av_codec_params->codec_type == AVMEDIA_TYPE_AUDIO)
        {
            cprintf("Audio Codec: %d channels, sample rate: %d", av_codec_params->channels, av_codec_params->sample_rate);
        }
        // 通用
        cprintf("Codec: %s ID %d bit_rate %d", pLocalCodec->long_name, pLocalCodec->id, av_codec_params->bit_rate);
    }

    // Video
    // 通过codec id 和 avcodec_find_decoder 函数可以找到对应已经注册的解码器，返回 AVCodec 指针，该组件能让我们知道如何编解码这个流。
    const AVCodec *av_codec_video = avcodec_find_decoder(av_stream_video->codecpar->codec_id);
    if (!av_codec_video)
    {
        UtilityFunctions::printerr("Codec not found video");
        close_video();
        return;
    }

    // 利用刚刚获取的 AVCodec 为 AVCodecContext 分配内存，它将维护解码/编码过程的上下文。
    av_codec_ctx_video = avcodec_alloc_context3(av_codec_video);
    if (!av_codec_ctx_video)
    {
        UtilityFunctions::printerr("Error allocating codec context video");
        close_video();
        return;
    }

    // 然后需要使用 avcodec_parameters_to_context和被编码流的参数(AVCodecParameters) 来填充 AVCodecContext。
    if (avcodec_parameters_to_context(av_codec_ctx_video, av_stream_video->codecpar) < 0)
    {
        UtilityFunctions::printerr("Error attaching codec parameters to codec context video");
        close_video();
        return;
    }

    // 启用视频多线程解码
    av_codec_ctx_video->thread_count = 0;
    // UtilityFunctions::print(av_codec_video->capabilities);
    if (av_codec_video->capabilities & AV_CODEC_CAP_FRAME_THREADS)
    {
        UtilityFunctions::print("Using frame-based threading for video");
        av_codec_ctx_video->thread_type = FF_THREAD_FRAME;
    }
    else if (av_codec_video->capabilities & AV_CODEC_CAP_SLICE_THREADS)
    {
        UtilityFunctions::print("Using slice-based threading for video");
        av_codec_ctx_video->thread_type = FF_THREAD_SLICE;
    }
    else
    {
        UtilityFunctions::print("Multi-threading not possible for video");
        av_codec_ctx_video->thread_count = 1; // 多线程不可用
    }

    // 完成上下文填充后，使用 avcodec_open2 来打开解码器。
    if (avcodec_open2(av_codec_ctx_video, av_codec_video, NULL) < 0)
    {
        UtilityFunctions::printerr("Error opening codec video");
        close_video();
        return;
    }

    // Setup SWSContext for convert video frame from YUV to RGB
    sws_ctx = sws_getContext(
        av_codec_ctx_video->width, av_codec_ctx_video->height, static_cast<AVPixelFormat>(av_stream_video->codecpar->format),
        av_codec_ctx_video->width, av_codec_ctx_video->height, AV_PIX_FMT_RGB24,
        SWS_BILINEAR, NULL, NULL, NULL);

    if (!sws_ctx)
    {
        UtilityFunctions::printerr("Error creating SWSContext for video");
        close_video();
        return;
    }

    // byte_array setup
    byte_array.resize(av_codec_ctx_video->width * av_codec_ctx_video->height * 3);
    src_linesize[0] = av_codec_ctx_video->width * 3;
    stream_time_base_video = av_q2d(av_stream_video->time_base);
    start_time_video = av_stream_video->start_time != AV_NOPTS_VALUE ? (long)(av_stream_video->start_time) : 0;
    start_time_video *= stream_time_base_video; // convert to pts_time
    average_frame_duration = 1 / av_q2d(av_stream_video->avg_frame_rate);
    UtilityFunctions::print_rich("[color=blue]Video time base[/color]: ", stream_time_base_video);
    UtilityFunctions::print_rich("[color=blue]Video frame rate[/color]: ", av_q2d(av_stream_video->avg_frame_rate));
    UtilityFunctions::print_rich("[color=blue]Video start time[/color]: ", start_time_video);
    _get_total_frame_number();

    // Audio
    const AVCodec *av_codec_audio = avcodec_find_decoder(av_stream_audio->codecpar->codec_id);
    if (!av_codec_audio)
    {
        UtilityFunctions::printerr("Codec not found audio");
        close_video();
        return;
    }

    av_codec_ctx_audio = avcodec_alloc_context3(av_codec_audio);
    if (!av_codec_ctx_audio)
    {
        UtilityFunctions::printerr("Error allocating codec context audio");
        close_video();
        return;
    }

    if (avcodec_parameters_to_context(av_codec_ctx_audio, av_stream_audio->codecpar) < 0)
    {
        UtilityFunctions::printerr("Error attaching codec parameters to codec context audio");
        close_video();
        return;
    }

    // 启用音频多线程解码
    av_codec_ctx_audio->thread_count = 0;
    // UtilityFunctions::print(av_codec_audio->capabilities);
    if (av_codec_audio->capabilities & AV_CODEC_CAP_FRAME_THREADS)
    {
        UtilityFunctions::print("Using frame-based threading for audio");
        av_codec_ctx_audio->thread_type = FF_THREAD_FRAME;
    }
    else if (av_codec_audio->capabilities & AV_CODEC_CAP_SLICE_THREADS)
    {
        UtilityFunctions::print("Using slice-based threading for audio");
        av_codec_ctx_audio->thread_type = FF_THREAD_SLICE;
    }
    else
    {
        UtilityFunctions::print("Multi-threading not possible for audio");
        av_codec_ctx_audio->thread_count = 1; // 多线程不可用
    }

    if (avcodec_open2(av_codec_ctx_audio, av_codec_audio, NULL) < 0)
    {
        UtilityFunctions::printerr("Error opening codec audio");
        close_video();
        return;
    }

    av_codec_ctx_audio->request_sample_fmt = AV_SAMPLE_FMT_S16;

    response = swr_alloc_set_opts2(
        &swr_ctx,
        &av_codec_ctx_audio->ch_layout, AV_SAMPLE_FMT_S16, av_codec_ctx_audio->sample_rate,
        &av_codec_ctx_audio->ch_layout, av_codec_ctx_audio->sample_fmt, av_codec_ctx_audio->sample_rate,
        0, nullptr);
    if (response < 0)
    {
        print_av_error("Fail to obtain swr context");
        close_video();
        return;
    }
    else if (!swr_ctx)
    {
        UtilityFunctions::printerr("Could not allocate re-sampler context");
        close_video();
        return;
    }

    response = swr_init(swr_ctx);
    if (response < 0)
    {
        print_av_error("Fail to initialize swr context");
        close_video();
        return;
    }

    stream_time_base_audio = av_q2d(av_stream_audio->time_base);
    start_time_audio = av_stream_audio->start_time != AV_NOPTS_VALUE ? (long)(av_stream_audio->start_time) : 0;
    start_time_audio *= stream_time_base_audio; // convert to pts_time

    cprintf("Video opened");
    is_open = true;
}

void Video::close_video()
{
    is_open = false;

    if (av_format_ctx)
        avformat_close_input(&av_format_ctx);

    if (av_codec_ctx_video)
        avcodec_free_context(&av_codec_ctx_video);

    if (av_codec_ctx_audio)
        avcodec_free_context(&av_codec_ctx_audio);

    if (swr_ctx)
        swr_free(&swr_ctx);

    if (sws_ctx)
        sws_freeContext(sws_ctx);

    if (av_frame)
        av_frame_free(&av_frame);

    if (av_packet)
        av_packet_free(&av_packet);
}

Ref<AudioStreamWAV> Video::get_audio()
{
    Ref<AudioStreamWAV> audio_wav = memnew(AudioStreamWAV);

    if (!is_open)
    {
        UtilityFunctions::printerr("Video not open yet!");
        return audio_wav;
    }

    response = av_seek_frame(av_format_ctx, av_stream_audio->index, start_time_audio, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_ANY);
    avcodec_flush_buffers(av_codec_ctx_audio);
    if (response < 0)
    {
        UtilityFunctions::printerr("Error seek to the beginning!");
        return audio_wav;
    }

    av_frame = av_frame_alloc();
    av_packet = av_packet_alloc();
    PackedByteArray audio_data = PackedByteArray();
    size_t audio_size = 0;

    while (av_read_frame(av_format_ctx, av_packet) >= 0)
    {
        if (av_packet->stream_index == av_stream_audio->index)
        {
            response = avcodec_send_packet(av_codec_ctx_audio, av_packet) == 0;
            if (response < 0)
            {
                UtilityFunctions::printerr("Error decoding audio packet");
                av_packet_unref(av_packet);
                break;
            }

            while (response >= 0)
            {
                response = avcodec_receive_frame(av_codec_ctx_audio, av_frame);
                if (response == AVERROR(EAGAIN) || response == AVERROR_EOF)
                {
                    break;
                }
                else if (response < 0)
                {
                    UtilityFunctions::printerr("Error decoding audio frame");
                    break;
                }

                AVFrame *av_new_frame = av_frame_alloc();
                av_new_frame->format = AV_SAMPLE_FMT_S16;
                av_new_frame->ch_layout = av_frame->ch_layout;
                av_new_frame->sample_rate = av_frame->sample_rate;
                av_new_frame->nb_samples = swr_get_out_samples(swr_ctx, av_frame->nb_samples);

                response = av_frame_get_buffer(av_new_frame, 0);
                if (response < 0)
                {
                    print_av_error("Could not create new frame for swr");
                    av_frame_unref(av_new_frame);
                    av_frame_unref(av_frame);
                    break;
                }

                response = swr_convert_frame(swr_ctx, av_new_frame, av_frame);
                if (response < 0)
                {
                    print_av_error("Could not convert audio frame");
                    av_frame_unref(av_new_frame);
                    av_frame_unref(av_frame);
                    break;
                }

                size_t frame_byte_size = av_new_frame->nb_samples * av_get_bytes_per_sample(AV_SAMPLE_FMT_S16);

                if (av_codec_ctx_audio->ch_layout.nb_channels >= 2)
                    frame_byte_size *= 2;

                audio_data.resize(audio_size + frame_byte_size);
                memcpy(audio_data.ptrw() + audio_size, av_new_frame->extended_data[0], frame_byte_size);
                audio_size += frame_byte_size;

                av_frame_unref(av_frame);
                av_frame_unref(av_new_frame);
            }
        }

        av_packet_unref(av_packet);
    }

    av_frame_free(&av_frame);
    av_packet_free(&av_packet);

    audio_wav->set_format(AudioStreamWAV::FORMAT_16_BITS);
    audio_wav->set_data(audio_data);
    audio_wav->set_mix_rate(av_codec_ctx_audio->sample_rate);
    audio_wav->set_stereo(av_codec_ctx_audio->ch_layout.nb_channels >= 2);

    return audio_wav;
}

Ref<Image> Video::seek_frame(int a_frame_number)
{
    Ref<Image> image = memnew(Image);
    if (!is_open)
    {
        UtilityFunctions::printerr("Video not open yet!");
        return image;
    }

    // 现在我们将从流中读取数据包并将它们解码为帧。但首先，需要为 AVPacket 和 AVFrame 分配内存。
    av_frame = av_frame_alloc();
    av_packet = av_packet_alloc();

    frame_timestamp = (long)(a_frame_number * average_frame_duration); // pts_time
    response = av_seek_frame(av_format_ctx, av_stream_video->index, (start_time_video + frame_timestamp) / stream_time_base_video, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_BACKWARD);
    avcodec_flush_buffers(av_codec_ctx_video);
    if (response < 0)
    {
        UtilityFunctions::printerr("Error seek to designated frame!");
        av_frame_free(&av_frame);
        av_packet_free(&av_packet);
        return image;
    }

    while (true)
    {
        // 使用函数 av_read_frame 读取帧数据来填充数据包
        // demux packet
        response = av_read_frame(av_format_ctx, av_packet);
        if (response != 0)
        {
            UtilityFunctions::printerr("Error reading frame");
            break;
        }
        if (av_packet->stream_index != av_stream_video->index)
        {
            av_packet_unref(av_packet);
            continue;
        }

        // 使用函数 avcodec_send_packet 来把原始数据包（未解压的帧）发送给解码器。
        // send packet for decoding
        response = avcodec_send_packet(av_codec_ctx_video, av_packet);
        av_packet_unref(av_packet);
        if (response != 0)
            break;

        // valid packet found, decode frame
        while (true)
        {
            // receive frame
            // 使用函数 avcodec_receive_frame 从解码器接受原始数据帧（解压后的帧）。
            response = avcodec_receive_frame(av_codec_ctx_video, av_frame);
            if (response != 0)
            {
                av_frame_unref(av_frame);
                break;
            }

            current_pts = av_frame->best_effort_timestamp == AV_NOPTS_VALUE ? av_frame->pts : av_frame->best_effort_timestamp;
            if (current_pts == AV_NOPTS_VALUE)
            {
                av_frame_unref(av_frame);
                continue;
            }

            if ((long)(current_pts * stream_time_base_video) < frame_timestamp)
            {
                av_frame_unref(av_frame);
                continue;
            }

            uint8_t *dest_data[1] = {byte_array.ptrw()};
            sws_scale(
                sws_ctx,
                av_frame->data, av_frame->linesize, 0, av_codec_ctx_video->height,
                dest_data, src_linesize);
            image->set_data(av_frame->width, av_frame->height, false, Image::Format::FORMAT_RGB8, byte_array);

            av_frame_unref(av_frame);
            av_frame_free(&av_frame);
            av_packet_free(&av_packet);

            return image;
        }
    }

    av_frame_free(&av_frame);
    av_packet_free(&av_packet);

    return image;
}

Ref<Image> Video::next_frame()
{
    Ref<Image> image = memnew(Image);
    if (!is_open)
    {
        UtilityFunctions::printerr("Video not open yet!");
        return image;
    }

    av_frame = av_frame_alloc();
    av_packet = av_packet_alloc();

    while (true)
    {
        // demux packet
        response = av_read_frame(av_format_ctx, av_packet);
        if (response < 0)
        {
            UtilityFunctions::printerr("Error reading frame");
            break;
        }
        if (av_packet->stream_index != av_stream_video->index)
        {
            av_packet_unref(av_packet);
            continue;
        }

        // send packet for decoding
        response = avcodec_send_packet(av_codec_ctx_video, av_packet);
        av_packet_unref(av_packet);
        if (response != 0)
            break;

        // valid packet found, decode frame
        while (true)
        {
            // receive frame
            response = avcodec_receive_frame(av_codec_ctx_video, av_frame);
            if (response != 0)
            {
                av_frame_unref(av_frame);
                break;
            }

            uint8_t *dest_data[1] = {byte_array.ptrw()};
            sws_scale(
                sws_ctx,
                av_frame->data, av_frame->linesize, 0, av_codec_ctx_video->height,
                dest_data, src_linesize);
            image->set_data(av_frame->width, av_frame->height, false, Image::Format::FORMAT_RGB8, byte_array);

            av_frame_unref(av_frame);
            av_frame_free(&av_frame);
            av_packet_free(&av_packet);

            return image;
        }
    }

    av_frame_free(&av_frame);
    av_packet_free(&av_packet);

    return image;
}

// av_stream_video->nb_frames 不准。
void Video::_get_total_frame_number()
{

    if (av_stream_video->nb_frames > 500)
        total_frame_number = av_stream_video->nb_frames - 30;

    av_packet = av_packet_alloc();
    av_frame = av_frame_alloc();

    // Video seeking
    frame_timestamp = (long)(total_frame_number * average_frame_duration);
    // UtilityFunctions::print_rich("[color=green]Video nb_frames[/color]: ", av_stream_video->nb_frames);
    // UtilityFunctions::print_rich("[color=green]Avg frame duration[/color]: ", average_frame_duration);
    // UtilityFunctions::print_rich("[color=green]Seek from frame timestamp[/color]: ", frame_timestamp);
    // UtilityFunctions::print_rich("[color=green]Start time video[/color]: ", start_time_video);
    response = av_seek_frame(av_format_ctx, av_stream_video->index, (start_time_video + frame_timestamp) / stream_time_base_video, AVSEEK_FLAG_FRAME | AVSEEK_FLAG_BACKWARD);

    avcodec_flush_buffers(av_codec_ctx_video);
    if (response < 0)
    {
        UtilityFunctions::printerr("Can't seek video stream!");
        av_frame_free(&av_frame);
        av_packet_free(&av_packet);
    }

    while (true)
    {

        // Demux packet
        response = av_read_frame(av_format_ctx, av_packet);
        if (response != 0)
            break;
        if (av_packet->stream_index != av_stream_video->index)
        {
            av_packet_unref(av_packet);
            continue;
        }

        // Send packet for decoding
        response = avcodec_send_packet(av_codec_ctx_video, av_packet);
        av_packet_unref(av_packet);
        if (response != 0)
            break;

        // Valid packet found, decode frame
        while (true)
        {

            // Receive all frames
            response = avcodec_receive_frame(av_codec_ctx_video, av_frame);
            if (response != 0)
            {
                av_frame_unref(av_frame);
                break;
            }

            // Get frame pts
            current_pts = av_frame->best_effort_timestamp == AV_NOPTS_VALUE ? av_frame->pts : av_frame->best_effort_timestamp;
            // UtilityFunctions::print_rich("[color=red]Frame pts[/color]: ", av_frame->pts);
            if (current_pts == AV_NOPTS_VALUE)
            {
                av_frame_unref(av_frame);
                continue;
            }

            // Skip to actual requested frame
            if ((long)(current_pts * stream_time_base_video) < frame_timestamp)
            {
                av_frame_unref(av_frame);
                continue;
            }

            total_frame_number++;
        }
    }
}

void Video::print_av_error(const char *a_message)
{
    char error_message[AV_ERROR_MAX_STRING_SIZE];
    av_strerror(response, error_message, sizeof(error_message));
    UtilityFunctions::printerr((std::string(a_message) + ": " + error_message).c_str());
}