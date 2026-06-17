#ifndef SETTINGS_H
#define SETTINGS_H

#include <QString>
#include <QSettings>

class Settings {
public:
    static Settings &instance();
    QString host() const;
    void setHost(const QString &h);
    int port() const;
    void setPort(int p);
private:
    Settings();
    QSettings m_settings;
};

#endif
