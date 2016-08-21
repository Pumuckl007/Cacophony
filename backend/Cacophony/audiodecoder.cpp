#include "audiodecoder.h"

#include <string>
#include <iostream>

using namespace std;

AudioDecoder::AudioDecoder()
{
    int err;
    m_decoder = opus_decoder_create(SAMPLE_RATE, CHANNELS, &err);
    if(err < 0){
        cout << "There was an error while initilizing the opus encoder: " << opus_strerror(err);
    }
}

AudioDecoder::~AudioDecoder(){
    opus_decoder_destroy(m_decoder);
}

int AudioDecoder::decode(unsigned char* opus_data, unsigned char* output, int length){
    opus_int16 decoded[MAX_PACKET_SIZE];
    int decodedLength = opus_decode(m_decoder, opus_data, length,  decoded, MAX_PACKET_SIZE, 0);
    for(int i = 0; i<decodedLength*2; i++){
        output[i*2+1] = (char)(decoded[i]>>8)&0xFF;
        output[i*2] = (char)(decoded[i])&0xFF;
    }
    return decodedLength*4;
}
