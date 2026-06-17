#include "devicedialog.h"
#include <QVBoxLayout>
#include <QFormLayout>
#include <QDialogButtonBox>
#include <QPushButton>

DeviceDialog::DeviceDialog(QWidget *parent) : QDialog(parent) {
    setWindowTitle("Add / Edit Device");
    auto *lay = new QVBoxLayout(this);
    auto *form = new QFormLayout;
    m_idEdit = new QLineEdit;
    m_typeEdit = new QLineEdit;
    m_iconCombo = new QComboBox;
    m_iconCombo->addItems({"lamp","traffic","sensor","camera","gateway","sign"});
    m_xSpin = new QDoubleSpinBox; m_xSpin->setRange(0, 800); m_xSpin->setDecimals(0);
    m_ySpin = new QDoubleSpinBox; m_ySpin->setRange(0, 600); m_ySpin->setDecimals(0);
    m_poweredCheck = new QCheckBox("Powered on");
    m_routerCheck = new QCheckBox("Is Router");
    form->addRow("ID:", m_idEdit);
    form->addRow("Type:", m_typeEdit);
    form->addRow("Icon:", m_iconCombo);
    form->addRow("X:", m_xSpin);
    form->addRow("Y:", m_ySpin);
    form->addRow(m_poweredCheck);
    form->addRow(m_routerCheck);
    lay->addLayout(form);
    auto *btns = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    lay->addWidget(btns);
    connect(btns, &QDialogButtonBox::accepted, this, &QDialog::accept);
    connect(btns, &QDialogButtonBox::rejected, this, &QDialog::reject);
    setStyleSheet("QDialog { background: #0a1428; } QLabel { color: #c8d8f0; } QLineEdit, QComboBox, QDoubleSpinBox { background: #040c18; color: #0af; border: 1px solid #1a3a6b; border-radius: 3px; padding: 4px; } QCheckBox { color: #c8d8f0; }");
}

void DeviceDialog::setDeviceData(const QJsonObject &dev) {
    m_idEdit->setText(dev["id"].toString());
    m_idEdit->setEnabled(false);
    m_typeEdit->setText(dev["type"].toString());
    m_iconCombo->setCurrentText(dev["icon"].toString());
    m_xSpin->setValue(dev["x"].toDouble());
    m_ySpin->setValue(dev["y"].toDouble());
    m_poweredCheck->setChecked(dev["powered"].toBool());
    m_routerCheck->setChecked(dev["is_router"].toBool());
}

QJsonObject DeviceDialog::deviceData() const {
    QJsonObject dev;
    dev["id"] = m_idEdit->text();
    dev["type"] = m_typeEdit->text();
    dev["icon"] = m_iconCombo->currentText();
    dev["x"] = m_xSpin->value();
    dev["y"] = m_ySpin->value();
    dev["powered"] = m_poweredCheck->isChecked();
    dev["is_router"] = m_routerCheck->isChecked();
    return dev;
}
