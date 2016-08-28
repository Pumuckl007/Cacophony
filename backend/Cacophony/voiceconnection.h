#ifndef VOICECONNECTION_H
#define VOICECONNECTION_H

#include <QObject>
#include <QBuffer>
#include <QFile>
#include <QTimer>
#include <QAudioInput>
#include <QAudioDeviceInfo>
#include <QAudioOutput>

#include <QDnsLookup>
#include <QHostAddress>
#include <QUdpSocket>

#include <audioencoder.h>
#include <audiodecoder.h>

#include <sodium.h>

class VoiceConnection : public QObject
{
    Q_OBJECT
    Q_PROPERTY( QString url READ connectionURL WRITE setConnectionURL )
    Q_PROPERTY( qint32 ssrc READ ssrc WRITE setSSRC )
    Q_PROPERTY( qint32 port READ port WRITE setPort )
    Q_PROPERTY( QString key READ key WRITE setKey)

public:
    explicit VoiceConnection(QObject *parent = 0);
    Q_INVOKABLE void connect();
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void encodeDecodeTest();
    Q_INVOKABLE void connectAndDiscover();
    Q_INVOKABLE QString getLocalAddress();
    Q_INVOKABLE quint16 getLocalPort();
    Q_INVOKABLE void startVoiceTransmission();
    Q_INVOKABLE void decodeTest();
    Q_INVOKABLE void mute(bool mute);
    Q_INVOKABLE void deafen(bool deaf);
    ~VoiceConnection();

public slots:
    void finishDNSLookup();
    void completeDiscovery();
    void continueDiscovery();
    void reciveData();
    void transmitVoiceData();
    void completeMetric();

signals:
    Q_SIGNAL void dNSFinished();
    Q_SIGNAL void discoveryFinished(QHostAddress localAddress, quint16 localPort);

protected:
    bool m_active;
    bool m_hasAddress;

    QString m_connectionURL;
    void setConnectionURL(QString url);
    QString connectionURL();

    char m_ssrc[4];
    void setSSRC(qint32 ssrc);
    qint32 ssrc();

    quint16 m_connectionPort;
    void setPort(quint16 port);
    quint16 port();

    QHostAddress m_localAddress;
    qint16 m_localPort;

    unsigned char m_key[crypto_secretbox_KEYBYTES];
    QString key();
    void setKey(QString key);

    QAudioDeviceInfo m_devInfo;
    QAudioInput *m_audioInput;
    QBuffer *m_audioData;
    QIODevice *m_playbackData;
    QAudioOutput *m_audioOutput;
    long m_readLocation;

    QTimer *m_timer;
    QDnsLookup *m_dns;
    QHostAddress *m_serverAddress;

    QUdpSocket *m_socket;

    AudioEncoder *m_encoder;
    AudioDecoder *m_decoder;

    int convert(QString string);
};


#endif // VOICECONNECTION_H

