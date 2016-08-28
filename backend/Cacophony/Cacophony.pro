TEMPLATE = lib
TARGET = Cacophonybackend
QT += qml quick
QT += multimedia
QT += network
CONFIG += qt plugin

load(ubuntu-click)

TARGET = $$qtLibraryTarget($$TARGET)

# Input
SOURCES += \
    backend.cpp \
    audioencoder.cpp \
    audiopacket.cpp \
    audiodecoder.cpp \
    voiceconnection.cpp \
    udpconnection.cpp

HEADERS += \
    backend.h \
    audioencoder.h \
    audiopacket.h \
    audiodecoder.h \
    voiceconnection.h \
    udpconnection.h


OTHER_FILES = qmldir

!equals(_PRO_FILE_PWD_, $$OUT_PWD) {
    copy_qmldir.target = $$OUT_PWD/qmldir
    copy_qmldir.depends = $$_PRO_FILE_PWD_/qmldir
    copy_qmldir.commands = $(COPY_FILE) \"$$replace(copy_qmldir.depends, /, $$QMAKE_DIR_SEP)\" \"$$replace(copy_qmldir.target, /, $$QMAKE_DIR_SEP)\"
    QMAKE_EXTRA_TARGETS += copy_qmldir
    PRE_TARGETDEPS += $$copy_qmldir.target
}

qmldir.files = qmldir
installPath = $${UBUNTU_CLICK_PLUGIN_PATH}/Cacophony
qmldir.path = $$installPath
target.path = $$installPath
INSTALLS += target qmldir

INCLUDEPATH += $$PWD/../opus/
DEPENDPATH += $$PWD/../opus/

LIBS += $$PWD/../opus/.libs/libopus.a

LIBS += $$OUT_PWD/../sodium/libsodium.a

INCLUDEPATH +=$$OUT_PWD/../sodium/

include($$PWD/../sodium/sodium.pri)

