#ifndef DEVICEPANEL_H
#define DEVICEPANEL_H

#include <QWidget>
#include <QLabel>
#include <QPushButton>
#include "models/device.h"

class DevicePanel : public QWidget {
    Q_OBJECT
public:
    explicit DevicePanel(QWidget *parent = nullptr);
    void showDevice(const Device &dev);
    void clear();

signals:
    void toggleRequested(const QString &id);
    void powerRequested(const QString &id);
    void deleteRequested(const QString &id);

private:
    QLabel *m_idLabel, *m_typeLabel, *m_statusLabel, *m_powerLabel, *m_signalLabel, *m_consumptionLabel, *m_iconLabel;
    QPushButton *m_toggleBtn, *m_powerBtn, *m_deleteBtn;
};

#endif
