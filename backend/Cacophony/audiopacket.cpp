#include "audiopacket.h"

#include <QDateTime>
#include <string>
#include <iostream>

using namespace std;

#define HEADER_SIZE 12

int AudioPacket::m_sequence = -1;
char* AudioPacket::m_ssrc = new char[4];

AudioPacket::AudioPacket(char* pcm, int length, unsigned char key[], char ssrc[], AudioEncoder* encoder)
{
    if(m_sequence < 0){
        if(sodium_init() < 0){
            cout << "Something went wrong with sodium intilazation!\n";
        }
        m_sequence = 0;
        m_ssrc = new char[4];
        for(int i = 0; i<4; i++){
            m_ssrc[i] = ssrc[i];
        }
    }
    m_sequence ++;
    m_dataIsPCM = true;
    for(unsigned int i = 0; i<crypto_secretbox_KEYBYTES; i++){
        m_key[i] = key[(int)i];
    }
    unsigned char* encoded = new unsigned char[AudioEncoder::MAX_PACKET_SIZE];
    int encodedLength = encoder->encode(pcm, encoded, length);
    unsigned char* encrypted = new unsigned char[encodedLength + crypto_secretbox_MACBYTES + HEADER_SIZE];
    encodedLength = encrypt(encoded, encrypted, encodedLength);
    delete encoded;
    m_finalData = encrypted;
    m_dataSize = encodedLength;
}

AudioPacket::AudioPacket(char* opus, int length, unsigned char key[], char ssrc[], AudioDecoder* decoder)
{
    if(m_sequence < 0){
        if(sodium_init() < 0){
            cout << "Something went wrong with sodium intilazation!\n";
        }
        randombytes_buf(m_ssrc, sizeof m_ssrc);
        m_sequence = 0;
        m_ssrc = new char[4];
        for(int i = 0; i<4; i++){
            m_ssrc[i] = ssrc[i];
        }
    }
    m_dataIsPCM = false;
    for(unsigned int i = 0; i<crypto_secretbox_KEYBYTES; i++){
        m_key[i] = key[(int)i];
    }
    unsigned char* unsignedData = new unsigned char[length];
    for(int i = 0; i<length; i++){
        unsignedData[i] = opus[i];
    }
    if(length - crypto_secretbox_MACBYTES - HEADER_SIZE < 1){

    } else {
        unsigned char* decrypted = new unsigned char[length - crypto_secretbox_MACBYTES - HEADER_SIZE];
        int decryptedLength = decrypt(unsignedData, decrypted, length);
        if(decryptedLength < 0){
            m_finalData = unsignedData;
            m_dataSize = length;
        } else {
            unsigned char* decoded = new unsigned char[AudioDecoder::MAX_PACKET_SIZE];
            int decodedLength = decoder->decode(decrypted, decoded, decryptedLength);
            m_finalData = decoded;
            m_dataSize = decodedLength;
        }
        delete decrypted;
        delete unsignedData;
        return;
    }
    m_finalData = unsignedData;
    m_dataSize = length;
}

int AudioPacket::encrypt(unsigned char* input, unsigned char* output, int length){
    unsigned char nonce[24];
    nonce[0] = 0x80;
    nonce[1] = 0x78;
    nonce[2] = m_sequence >> 8;
    nonce[3] = m_sequence;
    uint time = m_sequence*960;
    for(int i = 0; i<4; i++){
        nonce[7-i] = time;
        time = time >> 8;
    }
    for(int i = 0; i<4; i++){
        nonce[i+8] = m_ssrc[i];
    }
    for(int i = 0; i<12; i++){
        nonce[i+12] = 0;
        output[i] = nonce[i];
    }
    unsigned char* encrypted = new unsigned char[length + crypto_secretbox_MACBYTES];
    crypto_secretbox_easy(encrypted, input, length, nonce, m_key);
    length = length + crypto_secretbox_MACBYTES;
    for(int i = 0; i<length; i++){
        output[i+12] = encrypted[i];
    }
    delete encrypted;
    return length + 12;
}

int AudioPacket::size(){
    return m_dataSize;
}

bool AudioPacket::isDataPCM(){
    return m_dataIsPCM;
}

void AudioPacket::getData(char* toFill){
    for(int i = 0; i<m_dataSize; i++){
        toFill[i] = (char) m_finalData[i];
    }
}

int AudioPacket::decrypt(unsigned char* input, unsigned char* output, int length){
    unsigned char nonce[24];
    unsigned char encrypted[length - 12];
    for(int i = 0; i<length-12; i++){
        encrypted[i] = input[i+12];
    }
    for(int i = 0; i<12; i++){
        nonce[i] = input[i];
        nonce[i+12] = 0;
    }
    int decryptedLength = length - crypto_secretbox_MACBYTES - 12;
    if(decryptedLength < 0)
        return -1;
    int returnValue = crypto_secretbox_open_easy(output, encrypted, length-12, nonce, m_key);
    if(returnValue < 0){
        cout << "MESSAGE FORGED!\n";
        return -1;
    }
    return decryptedLength;
}

AudioPacket::~AudioPacket(){
    if(m_finalData)
        delete m_finalData;
}

