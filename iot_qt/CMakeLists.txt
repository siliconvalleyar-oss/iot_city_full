cmake_minimum_required(VERSION 3.16)
project(iot_qt VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 QUIET COMPONENTS Core Widgets Network WebSockets Charts)
if(Qt6_FOUND)
    set(QT_LIBS Qt6::Core Qt6::Widgets Qt6::Network Qt6::WebSockets Qt6::Charts)
    message(STATUS "Using Qt6")
else()
    find_package(Qt5 5.15 REQUIRED COMPONENTS Core Widgets Network WebSockets Charts)
    set(QT_LIBS Qt5::Core Qt5::Widgets Qt5::Network Qt5::WebSockets Qt5::Charts)
    message(STATUS "Using Qt5")
endif()

set(SOURCES
    src/main.cpp src/mainwindow.cpp
    src/models/device.cpp src/models/dashboardmetrics.cpp
    src/network/apiclient.cpp src/network/websocketclient.cpp
    src/widgets/mapwidget.cpp src/widgets/devicepanel.cpp
    src/widgets/dashboardwidget.cpp src/widgets/devicedialog.cpp
    src/widgets/logpanel.cpp src/utils/settings.cpp
)

set(HEADERS
    src/mainwindow.h src/models/device.h src/models/dashboardmetrics.h
    src/network/apiclient.h src/network/websocketclient.h
    src/widgets/mapwidget.h src/widgets/devicepanel.h src/widgets/dashboardwidget.h
    src/widgets/devicedialog.h src/widgets/logpanel.h src/utils/settings.h
)

add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})
target_include_directories(${PROJECT_NAME} PRIVATE src)
target_link_libraries(${PROJECT_NAME} PRIVATE ${QT_LIBS})

if(QT_VERSION_MAJOR EQUAL 5)
    target_compile_definitions(${PROJECT_NAME} PRIVATE QT_DISABLE_DEPRECATED_BEFORE=0x050F00)
endif()
