#ifndef UDPCONNECTION_H
#define UDPCONNECTION_H

#include <QObject>
#include <QUdpSocket>
#include <QHostAddress>

class UDPConnection : public QObject
{
    Q_OBJECT

public:
    explicit UDPConnection(QObject *parent = 0);
    explicit UDPConnection(QObject *parent, QHostAddress url, qint32 port);
    ~UDPConnection();


Q_SIGNALS:

protected:
    qint32 m_port;
    QUdpSocket *m_socket;

};

#endif // UDPCONNECTION_H
