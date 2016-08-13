#include "mytype.h"

#include <string>
#include <iostream>
#include <QTimer>
#include <string.h>
#include <QFile>

#define FRAME_SIZE 1920
#define MAX_PACKET_SIZE (3*1276)

using namespace std;

MyType::MyType(QObject *parent) :
    QObject(parent),
    m_active(false),
    m_devInfo(QAudioDeviceInfo::defaultInputDevice()),
    m_audioData(new QBuffer()),
    m_initilized(false),
    m_sequence(0),
    theOutput("/tmp/output.opus"),
    m_readLocation(0)
{

}

MyType::~MyType() {

}

void MyType::setConnectionURL(QString url)
{
    if(m_active){
        delete &m_audioInput;
    }
    m_active = false;
    m_connectionURL = url;
}

void MyType::connect()
{
    theOutput.open(QBuffer::WriteOnly);
    m_audioData->open(QBuffer::ReadWrite);
    randombytes_buf(key, sizeof key);
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleSize(8);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::UnSignedInt);
    if(m_devInfo.isFormatSupported(format)){
        cout << "Format " << format.codec().toStdString() << " is supported";
        m_audioInput = new QAudioInput(format, this);
        cout << "Format is " << m_audioInput->format().codec().toStdString() << "\n";
        m_timer = new QTimer(this);
        QTimer::connect(m_timer, SIGNAL(timeout()), this, SLOT(encode()));
        m_timer->start(70);
        QTimer::singleShot(30000, this, SLOT(stopRecording()));
        m_audioInput->start(m_audioData);
    } else {
        cout << "Format " << format.codec().toStdString() << " is not supported";
    }

}

int MyType::makePacket(char* input, char* output, const unsigned char *key, int inputLength){
    if(!m_initilized){
        //Sodium setup
        if(sodium_init() < 0){
            cout << "Something went really wrong with sodium intilazation!\n";
            return -1;
        }

        //Opus Setup
        int err;
        encoder = opus_encoder_create(48000, 2, OPUS_APPLICATION_VOIP, &err);
        opus_encoder_ctl(encoder, OPUS_SET_BITRATE((opus_int32) 64000));
        if (err<0)
        {
           cout << "failed to create an encoder: " << opus_strerror(err) << "\n";
           return -1;
        }

        //Header Setup
        header[0] = 0x80;
        header[1] = 0x78;
        for(int i = 2; i<12; i++){
            header[i] = 0;
        }
        randombytes_buf(m_ssrc, sizeof m_ssrc);
        for(int i = 0; i<4; i++){
            header[i+8] = m_ssrc[i];
        }
        m_initilized = true;
    }
    header[2] = m_sequence >> 8;
    header[3] = m_sequence;
    unsigned int time = (960*m_sequence);
    for(int i = 0; i<4; i++){
        header[7-i] = time;
        time = time >> 8;
    }
    m_sequence++;
    unsigned char nonce[24];
    for(int i = 0; i<12; i++){
        nonce[i] = header[i];
        nonce[i+12] = 0;
    }
    unsigned char encoded[MAX_PACKET_SIZE + crypto_secretbox_MACBYTES];

    opus_int16 preEncoded[inputLength];
    for(int i = 0; i<inputLength; i++){
        preEncoded[i] = (opus_int16)input[i];
    }

    int compressedLength = opus_encode(encoder, preEncoded, inputLength/4, encoded, MAX_PACKET_SIZE);

    if(compressedLength < 0){
        cout << opus_strerror(compressedLength);
        return compressedLength;
    }

    unsigned char outputUnsigned[compressedLength + crypto_secretbox_MACBYTES];

    crypto_secretbox_easy(outputUnsigned, encoded, compressedLength, nonce, key);

    for(unsigned int i = 0; i<compressedLength + crypto_secretbox_MACBYTES; i++){
        output[i] = (char) outputUnsigned[i];
    }

    return compressedLength + crypto_secretbox_MACBYTES;
}

void MyType::encode(){
    char* inputChars = new char[FRAME_SIZE*4];
    char outputChars[MAX_PACKET_SIZE + crypto_secretbox_MACBYTES];
    int inputLength = -1;
    int size = m_audioData->size();
    while(m_readLocation < size-FRAME_SIZE*4){
        m_audioData->seek(m_readLocation);
        inputLength = m_audioData->read(inputChars, FRAME_SIZE*4);
        if(inputLength < FRAME_SIZE*4){
            cout << inputLength << "\n";
            break;
        }
        int packetSize = makePacket(inputChars, outputChars, key, inputLength);
        if(packetSize > -1)
            theOutput.write(outputChars, packetSize);
        m_readLocation += FRAME_SIZE*4;
    }
}

void MyType::stopRecording()
{
    m_timer->stop();
    encode();
    m_audioInput->stop();
    m_audioData->close();
    theOutput.close();
    delete m_audioInput;
}

QString MyType::connectionURL()
{
    return m_connectionURL;

}
