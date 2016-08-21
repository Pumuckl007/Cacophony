#include "audioencoder.h"
#include <string>
#include <iostream>

using namespace std;


AudioEncoder::AudioEncoder(int bitrate)
{
    int err;
    m_encoder = opus_encoder_create(SAMPLE_RATE, CHANNELS, OPUS_APPLICATION_VOIP, &err);
    if(err < 0){
        cout << "There was an error while initilizing the opus encoder: " << opus_strerror(err);
    }
    if(bitrate > 5000){
        err = opus_encoder_ctl(m_encoder, OPUS_SET_BITRATE(bitrate));
        if(err < 0){
            cout << "There was an error while setting the bitrate of the opus encoder: " << opus_strerror(err);
        }
    }
}

int AudioEncoder::setBitrate(int bitrate){
    int err;
    err = opus_encoder_ctl(m_encoder, OPUS_SET_BITRATE(bitrate));
    if(err < 0){
        cout << "There was an error while setting the bitrate of the opus encoder: " << opus_strerror(err);
    }
    return err;
}

AudioEncoder::~AudioEncoder(){
    opus_encoder_destroy(m_encoder);
}

int AudioEncoder::encode(const char* pcm_data, unsigned char* output, int length){
    opus_int16 bitData[length/2];
    for(int i = 0; i<length/2; i++){
        bitData[i] = ((opus_int16)pcm_data[i*2]);
        bitData[i] += (((opus_int16)pcm_data[i*2+1])<<8);
    }
    int encodedLength = opus_encode(m_encoder, bitData, length/2/CHANNELS, output, MAX_PACKET_SIZE);
    if(encodedLength < 0){
        cout << "There was an error while encoding: " << opus_strerror(length);
    }
    return encodedLength;
}

