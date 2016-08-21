#ifndef AUDIOPACKET_H
#define AUDIOPACKET_H

#include <sodium.h>
#include "audioencoder.h"
#include "audiodecoder.h"

class AudioPacket
{
public:
    explicit AudioPacket(char* pcm, int length, unsigned char key[], char ssrc[], AudioEncoder* encoder);
    explicit AudioPacket(char* opus, int length, unsigned char key[], char ssrc[], AudioDecoder* decoder);
    ~AudioPacket();
    int size();
    bool isDataPCM();
    void getData(char* toFill);
    static int m_sequence;
    static char* m_ssrc;

private:
    unsigned char* m_finalData;
    int m_dataSize;
    bool m_dataIsPCM;
    unsigned char m_key[crypto_secretbox_KEYBYTES];
    int encrypt(unsigned char* input, unsigned char* output, int length);
    int decrypt(unsigned char* input, unsigned char* output, int length);
};

#endif // AUDIOPACKET_H
