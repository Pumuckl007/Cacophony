#ifndef MYTYPE_H
#define MYTYPE_H

#include <QObject>
#include <QBuffer>
#include <QFile>
#include <QTimer>
#include <QAudioInput>
#include <QAudioDeviceInfo>
#include <opus.h>
#include <sodium.h>


class MyType : public QObject
{
    Q_OBJECT
    Q_PROPERTY( QString url READ connectionURL WRITE setConnectionURL )

public:
    explicit MyType(QObject *parent = 0);
    Q_INVOKABLE void connect();
    Q_INVOKABLE void stopRecording();
    ~MyType();

Q_SIGNALS:

protected:
    Q_INVOKABLE void encode();
    QString m_connectionURL;
    void setConnectionURL(QString url);
    QString connectionURL();
    bool m_active;
    QAudioDeviceInfo m_devInfo;
    QAudioInput *m_audioInput;
    OpusEncoder *encoder;
    QBuffer *m_audioData;
    bool m_initilized;
    int makePacket(char* input, char* output, const unsigned char *key, int inputLength);
    unsigned char header[12];
    int m_sequence;
    unsigned char m_ssrc[4];
    QFile theOutput;
    unsigned char key[crypto_secretbox_KEYBYTES];
    unsigned long m_readLocation;
    QTimer *m_timer;
};


#endif // MYTYPE_H

