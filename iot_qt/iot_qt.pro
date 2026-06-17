QT       += core gui widgets network websockets charts
CONFIG   += c++17
TARGET    = iot_qt
TEMPLATE  = app

SOURCES += \
    src/main.cpp \
    src/mainwindow.cpp \
    src/models/device.cpp \
    src/models/dashboardmetrics.cpp \
    src/network/apiclient.cpp \
    src/network/websocketclient.cpp \
    src/widgets/mapwidget.cpp \
    src/widgets/devicepanel.cpp \
    src/widgets/dashboardwidget.cpp \
    src/widgets/devicedialog.cpp \
    src/widgets/logpanel.cpp \
    src/utils/settings.cpp

HEADERS += \
    src/mainwindow.h \
    src/models/device.h \
    src/models/dashboardmetrics.h \
    src/network/apiclient.h \
    src/network/websocketclient.h \
    src/widgets/mapwidget.h \
    src/widgets/devicepanel.h \
    src/widgets/dashboardwidget.h \
    src/widgets/devicedialog.h \
    src/widgets/logpanel.h \
    src/utils/settings.h

RESOURCES += resources.qrc

INCLUDEPATH += src
