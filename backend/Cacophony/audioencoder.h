#ifndef AUDIOENCODER_H
#define AUDIOENCODER_H

#include <opus.h>


class AudioEncoder
{
public:
    explicit AudioEncoder(int bitrate);
    ~AudioEncoder();
    int encode(const char* pcm_data, unsigned char* output, int length);
    int setBitrate(int bitrate);
    static const int MAX_PACKET_SIZE = 5*1920;
    static const int CHANNELS = 2;
    static const int SAMPLE_RATE = 48000;

private:
    OpusEncoder *m_encoder;
};

#endif // AUDIOENCODER_H
