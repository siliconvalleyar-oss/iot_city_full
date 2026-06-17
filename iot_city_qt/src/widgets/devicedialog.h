#ifndef DEVICEDIALOG_H
#define DEVICEDIALOG_H

#include <QDialog>
#include <QLineEdit>
#include <QComboBox>
#include <QDoubleSpinBox>
#include <QCheckBox>
#include <QJsonObject>
#include <QMap>

class DeviceDialog : public QDialog {
    Q_OBJECT
public:
    explicit DeviceDialog(QWidget *parent = nullptr);
    QJsonObject deviceData() const;
    void setDeviceData(const QJsonObject &dev);

private:
    QLineEdit *m_idEdit, *m_typeEdit;
    QComboBox *m_iconCombo;
    QDoubleSpinBox *m_xSpin, *m_ySpin;
    QCheckBox *m_poweredCheck, *m_routerCheck;
};

#endif
