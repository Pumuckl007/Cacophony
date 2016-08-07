#include "mytype.h"

#include <string>
#include <iostream>
#include <QTimer>
#include <opus.h>
#include <string.h>
#include <QFile>

using namespace std;

MyType::MyType(QObject *parent) :
    QObject(parent),
    m_active(false),
    m_devInfo(QAudioDeviceInfo::defaultInputDevice()),
    m_audioData(new QBuffer())
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
    m_audioData->open(QBuffer::ReadWrite);
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleSize(8);
    format.setCodec("audio/opus");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::UnSignedInt);
    if(m_devInfo.isFormatSupported(format)){
        cout << "Format " << format.codec().toStdString() << " is supported";
        m_audioInput = new QAudioInput(format, this);
        cout << "Format is " << m_audioInput->format().codec().toStdString() << "\n";
        QTimer::singleShot(1000, this, SLOT(stopRecording()));

        //Opus Setup
        int err;
        encoder = opus_encoder_create(format.sampleRate(), format.channelCount(), OPUS_APPLICATION_AUDIO, &err);
        if (err<0)
        {
           cout << "failed to create an encoder: " << opus_strerror(err) << "\n";
           return;
        }
        err = opus_encoder_ctl(encoder, OPUS_SET_BITRATE(64000));
        if (err<0)
        {
            cout << "failed to set bitrate: " << opus_strerror(err) << "\n";
            return;
        }
        //QObject::connect(m_audioInput, SIGNAL(notify()), this, SLOT(encode()));
        //m_audioInput->setNotifyInterval(50);
        m_audioInput->start(m_audioData);
    } else {
        cout << "Format " << format.codec().toStdString() << " is not supported";
    }

}

void MyType::encode(){
    QFile file("/tmp/recording.opus");
    file.open(QIODevice::WriteOnly);
    int read = 0;
    int size = 0;
    char * in = new char[2048];
    opus_int16 data[2048];
    unsigned char output[2048];
    char converterAgain[2048];
    while(read < m_audioData->size()){
        m_audioData->seek(read);
        m_audioData->read(in, 2048);
        for(int i = 0; i<2048; i++){
            data[i] = (opus_int16)in[i];
        }
        size = (m_audioData->size()-read > 2048) ? 2048 : m_audioData->size()-read;
        if(size == 2048){
            int returnCode = opus_encode(encoder, data, 480, output, 2048);
            const char* error = opus_strerror(returnCode);
            cout << error;
            for(int k = 0; k<2048; k++){
                converterAgain[k] = (char) output[k];
            }
            file.write(converterAgain, size);
        }
        read += 2048;
    }
    cout << "encode! " << m_audioData->size() << "\n";
}

void MyType::stopRecording()
{
    encode();
    m_audioInput->stop();
    m_audioData->close();
    delete m_audioInput;
}

QString MyType::connectionURL()
{
    return m_connectionURL;

}
