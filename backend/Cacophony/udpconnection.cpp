#include "udpconnection.h"

#include <QList>
#include <QDnsServiceRecord>
#include <string>
#include <iostream>
#include <QHostAddress>

using namespace std;

UDPConnection::UDPConnection(QObject *parent) : QObject(parent)
{

}

UDPConnection::~UDPConnection(){

}

//void UDPConnection::initUDP(QString url, qint32 port){

//    if(url.startsWith("wss://")){
//        url = url.right(7);
//    }
//    int index;
//    if((index = url.indexOf(':')) != -1){
//        url = url.left(index-1);
//    }
//    m_port = port;
//    m_dns = new QDnsLookup(this);
//    QObject::connect(m_dns, SIGNAL(finished()), this, SLOT(finished()));
//    m_dns->setType(QDnsLookup::A);
//    m_dns->setName("example.com");
//    m_dns->lookup();
//    qDebug("Looking up");
//}

//void UDPConnection::finished(){
//    qDebug("Finished");
//    if(m_dns->error() != QDnsLookup::NoError){
//        qWarning("DNS Lookup for UDP connection Failed!");
//        qWarning("%s", m_dns->errorString().toStdString().c_str());
//        m_dns->deleteLater();
//        return;
//    }
//    const QList<QDnsHostAddressRecord> records = m_dns->hostAddressRecords();
//    int address = -1;
//    for(int i = 0; i<records.length(); i++){
//        QDnsHostAddressRecord record = records.at(i);
//        address = record.value().toIPv4Address();
//    }
//    m_dns->deleteLater();
//}
