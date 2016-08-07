#ifndef MYTYPE_H
#define MYTYPE_H

#include <QObject>
#include <QBuffer>
#include <QAudioInput>
#include <QAudioDeviceInfo>
#include <opus.h>


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
};


#endif // MYTYPE_H

