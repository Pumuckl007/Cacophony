TEMPLATE = lib
TARGET = Cacophonybackend
QT += qml quick
QT += multimedia
CONFIG += qt plugin

load(ubuntu-click)

TARGET = $$qtLibraryTarget($$TARGET)

# Input
SOURCES += \
    backend.cpp \
    mytype.cpp

HEADERS += \
    backend.h \
    mytype.h


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

LIBS += -L$$PWD/3rdparty/opus/lib/ -lopus

INCLUDEPATH += $$PWD/3rdparty/opus/include
DEPENDPATH += $$PWD/3rdparty/opus/include

LIBS += -L$$PWD/3rdparty/sodium/lib/ -lsodium

INCLUDEPATH += $$PWD/3rdparty/sodium/include
DEPENDPATH += $$PWD/3rdparty/sodium/include
