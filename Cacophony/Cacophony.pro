TEMPLATE = aux
TARGET = Cacophony

RESOURCES += Cacophony.qrc

QML_FILES += $$files(*.qml,true) \
             $$files(*.js,true)

CONF_FILES +=  Cacophony.apparmor \
               Cacophony.png \
               DownCaret.svg

AP_TEST_FILES += tests/autopilot/run \
                 $$files(tests/*.py,true)               

OTHER_FILES += $${CONF_FILES} \
               $${QML_FILES} \
               $${AP_TEST_FILES} \
               Cacophony.desktop

#specify where the qml/js files are installed to
qml_files.path = /Cacophony
qml_files.files += $${QML_FILES}

#specify where the config files are installed to
config_files.path = /Cacophony
config_files.files += $${CONF_FILES}

#install the desktop file, a translated version is 
#automatically created in the build directory
desktop_file.path = /Cacophony
desktop_file.files = $$OUT_PWD/Cacophony.desktop
desktop_file.CONFIG += no_check_exist

INSTALLS+=config_files qml_files desktop_file

DISTFILES += \
    DiscordInterface.js \
    Websocket.qml \
    ChatMessageDisplay.qml \
    ChatPage.qml \
    FriendDisplay.qml \
    ServerDisplay.qml \
    FriendsAndServers.qml \
    Server.qml \
    ChannelDisplay.qml \
    NewChannel.qml \
    ServerUsers.qml \
    VoiceChannels.qml

