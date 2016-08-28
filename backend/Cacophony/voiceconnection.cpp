#include "voiceconnection.h"

#include <QTimer>
#include <string.h>
#include <QFile>
#include <QChar>
#include <QAudioDeviceInfo>
#include "audioencoder.h"
#include "audiopacket.h"
#include <sodium.h>

#include <QDateTime>

#define FRAME_SIZE 48000*2/100
#define MAX_FRAME_SIZE 6*FRAME_SIZE

using namespace std;

VoiceConnection::VoiceConnection(QObject *parent) :
    QObject(parent),
    m_active(false),
    m_hasAddress(false),
    m_connectionPort(-1),
    m_localPort(-1),
    m_readLocation(0),
    m_encoder(new AudioEncoder(64000)),
    m_decoder(new AudioDecoder())
{
//    m_playbackData = new QBuffer();
//    m_playbackData->open(QBuffer::ReadWrite);
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleSize(16);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::SignedInt);
    QAudioDeviceInfo info = QAudioDeviceInfo::defaultOutputDevice();
    if(info.isFormatSupported(format)){
        m_audioOutput = new QAudioOutput(format, this);
        m_audioOutput->setVolume(1);
        m_playbackData =  m_audioOutput->start();
    } else {
        format = info.nearestFormat(format);
        m_audioOutput = new QAudioOutput(format, this);
        qDebug("New but still the same?");
    }
}

VoiceConnection::~VoiceConnection() {

}

void VoiceConnection::setConnectionURL(QString url)
{
    if(m_active){
        qWarning("error can not set url while active");
        return;
    }
    if(m_hasAddress){
        delete m_serverAddress;
        m_hasAddress = false;
    }
    m_dns = new QDnsLookup(this);
    QObject::connect(m_dns, SIGNAL(finished()), this, SLOT(finishDNSLookup()));
    m_dns->setType(QDnsLookup::A);
    m_dns->setName(url);
    m_dns->lookup();
}

void VoiceConnection::finishDNSLookup(){
    if(m_dns->error() != QDnsLookup::NoError){
        qWarning("DNS Lookup for UDP connection Failed!");
        qWarning("%s", m_dns->errorString().toStdString().c_str());
        m_dns->deleteLater();
        return;
    }
    const QList<QDnsHostAddressRecord> records = m_dns->hostAddressRecords();
    if(records.length() > 0){
        m_hasAddress = true;
        m_serverAddress = new QHostAddress(records.at(0).value());
        qDebug("DNS looked up for %s whos address is %s", records.at(0).name().toStdString().c_str(), m_serverAddress->toString().toStdString().c_str());
    }
    m_dns->deleteLater();
    emit dNSFinished();
}

QString VoiceConnection::connectionURL()
{
    return m_connectionURL;
}

void VoiceConnection::setSSRC(qint32 ssrc){
    for(int i = 0; i<4; i++){
        m_ssrc[3-i] = ssrc;
        ssrc = ssrc >> 8;
    }
}

qint32 VoiceConnection::ssrc(){
    qint32 ssrc = 0;
    for(int i = 0; i<4; i++){
        ssrc += m_ssrc[i] << (3-i);
    }
    return ssrc;
}

void VoiceConnection::setPort(quint16 port){
    m_connectionPort = port;
}

quint16 VoiceConnection::port(){
    return m_connectionPort;
}

void VoiceConnection::setKey(QString key){
    QStringList bytes = key.replace('[', ' ').replace(']', ' ').trimmed().split(',');
    for(unsigned int i = 0; i<crypto_secretbox_KEYBYTES; i++){
        m_key[i] = (unsigned char) convert(bytes.at(i));
    }
}

int VoiceConnection::convert(QString string){
    int number = 0;
    for(int i = 0; i<string.length(); i++){
        if(string.at(i).digitValue() != 32){
            number += string.at(i).digitValue();
            number *= 10;
        }
    }
    number /= 10;
    return number;
}

QString VoiceConnection::key(){
    QByteArray array(new char[0]);
    return array;
}

void VoiceConnection::connectAndDiscover(){
    if(m_active){
        qWarning("Cannot start a new connection while this one is already active!");
        return;
    }
    if(!m_hasAddress){
        qWarning("The Voice connection needs an address inorder to start!");
        return;
    }
    m_active = true;
    m_socket = new QUdpSocket(this);
    QObject::connect(m_socket, SIGNAL(readyRead()),
                     this, SLOT(completeDiscovery()));
    QObject::connect(m_socket, SIGNAL(connected()),
                     this, SLOT(continueDiscovery()));
    m_socket->bind(26235, QUdpSocket::DefaultForPlatform);
    m_socket->connectToHost(*m_serverAddress, m_connectionPort);
}

void VoiceConnection::continueDiscovery(){
    if(!m_socket->isWritable() || m_socket->state() != QUdpSocket::ConnectedState){
        qDebug("UDP socket is not open! %s",  m_socket->errorString().toStdString().c_str());
        return;
    }
    qDebug("UDP connection ready!");
    char data[70];
    for(int i = 0; i<4; i++){
        data[i] = m_ssrc[3-i];
    }
    for(int i = 4; i<70; i++){
        data[i] = 0;
    }
    m_socket->write(data, 70);
}

void VoiceConnection::completeDiscovery(){
    while(m_socket->hasPendingDatagrams()){
        QByteArray datagram;
        datagram.resize(m_socket->pendingDatagramSize());
        QHostAddress sender;
        quint16 senderPort;

        m_socket->readDatagram(datagram.data(), datagram.size(), &sender, &senderPort);

        m_localPort = datagram.at(datagram.size()-1);
        m_localPort += datagram.at(datagram.size()-2) << 8;

        QString myIp = QString(datagram.right(datagram.size() - 4).left(datagram.indexOf('\0', 4)- 4));
        m_localAddress = QHostAddress(myIp);
        qDebug("Found local IP: %s", myIp.toStdString().c_str());
        break;
    }
    QObject::disconnect(m_socket, SIGNAL(readyRead()),
                     this, SLOT(completeDiscovery()));
    QObject::connect(m_socket, SIGNAL(readyRead()),
                     this, SLOT(reciveData()));
    emit discoveryFinished(m_localAddress, m_localPort);
}

QString VoiceConnection::getLocalAddress(){
    return m_localAddress.toString();
}

quint16 VoiceConnection::getLocalPort(){
    return m_localPort;
}

void VoiceConnection::reciveData(){
    if(m_audioOutput->state() != QAudio::ActiveState){
        m_playbackData = m_audioOutput->start();
    }
    while (m_socket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(m_socket->pendingDatagramSize());
        QHostAddress sender;
        quint16 senderPort;

        m_socket->readDatagram(datagram.data(), datagram.size(),
            &sender, &senderPort);

        AudioPacket packet(datagram.data(), datagram.size(), m_key, m_ssrc, m_decoder);
        char data[packet.size()];
        packet.getData(data);
        m_playbackData->write(data, packet.size());
    }
}

void VoiceConnection::startVoiceTransmission()
{
    m_audioData = new QBuffer();
    m_audioData->open(QBuffer::ReadWrite);
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleSize(16);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::SignedInt);
    QAudioDeviceInfo info = QAudioDeviceInfo::defaultInputDevice();
    if(info.isFormatSupported(format)){
        m_audioInput = new QAudioInput(format, this);
        m_timer = new QTimer(this);
        QTimer::connect(m_timer, SIGNAL(timeout()), this, SLOT(transmitVoiceData()));
        m_timer->start(20);
        m_audioInput->start(m_audioData);
    } else {
            format = info.nearestFormat(format);
        qWarning("Format %s is not supported %d %d %d", format.codec().toStdString().c_str(), format.sampleRate(), format.channelCount(), format.sampleSize());
    }
    m_readLocation = 0;
}

void VoiceConnection::transmitVoiceData(){
    char pcm[FRAME_SIZE*4];
    if(m_audioData->size() > m_readLocation + FRAME_SIZE*4){
        int pos = m_audioData->pos();
        m_audioData->seek(m_readLocation);
        int read = m_audioData->read(pcm, FRAME_SIZE*4);
        m_audioData->seek(pos);
        if(read < FRAME_SIZE*4){
            qDebug("Frame Dropped");
            return;
        }
        m_readLocation += read;
        AudioPacket packet(pcm, read, m_key, m_ssrc, m_encoder);
        char *data = new char[packet.size()];
        packet.getData(data);
        m_socket->write(data, packet.size());
    } else {
        qWarning("Microphone buffer underflow!");
    }
}

void VoiceConnection::mute(bool mute){
    if(m_active){
        if(mute){
            m_audioInput->suspend();
            char pcm[FRAME_SIZE*4];
            for(int i = 0; i<FRAME_SIZE*4; i++){
                pcm[i] = 0;
            }
            AudioPacket packet(pcm, FRAME_SIZE*4, m_key, m_ssrc, m_encoder);
            char data[packet.size()];
            packet.getData(data);
            m_socket->write(data);
        } else {
            m_audioInput->resume();
        }
    }
}

void VoiceConnection::deafen(bool deaf){
    if(deaf){
        m_audioOutput->setVolume(0);
    } else {
        m_audioOutput->setVolume(1);
    }
}
