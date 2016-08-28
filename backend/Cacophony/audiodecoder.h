#ifndef AUDIODECODER_H
#define AUDIODECODER_H

#include "opus.h"


class AudioDecoder
{
public:
    explicit AudioDecoder();
    ~AudioDecoder();
    int decode(unsigned char* opus_data, unsigned char* output, int length);
    static const int MAX_PACKET_SIZE = 5*1920;
    static const int CHANNELS = 2;
    static const int SAMPLE_RATE = 48000;

private:
    OpusDecoder *m_decoder;
};

#endif // AUDIODECODER_H
