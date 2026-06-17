#include "settings.h"

Settings &Settings::instance() { static Settings s; return s; }
Settings::Settings() : m_settings("IoT-City", "iot-city-qt") {}
QString Settings::host() const { return m_settings.value("host", "ms7851.local").toString(); }
void Settings::setHost(const QString &h) { m_settings.setValue("host", h); }
int Settings::port() const { return m_settings.value("port", 5062).toInt(); }
void Settings::setPort(int p) { m_settings.setValue("port", p); }
