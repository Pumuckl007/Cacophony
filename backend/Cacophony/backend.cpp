#include <QtQml>
#include <QtQml/QQmlContext>
#include "backend.h"
#include "voiceconnection.h"
#include "audiodecoder.h"
#include "audioencoder.h"
#include "audiopacket.h"
#include "udpconnection.h"


void BackendPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Cacophony"));

    qmlRegisterType<VoiceConnection>(uri, 1, 0, "VoiceConnection");
    qmlRegisterType<UDPConnection>(uri, 1, 0, "UDPConnection");

}

void BackendPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}
