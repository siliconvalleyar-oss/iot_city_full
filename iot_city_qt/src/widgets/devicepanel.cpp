#include "devicepanel.h"
#include <QVBoxLayout>
#include <QGroupBox>
#include <QFormLayout>

DevicePanel::DevicePanel(QWidget *parent) : QWidget(parent) {
    auto *mainLay = new QVBoxLayout(this);
    auto *gb = new QGroupBox("Device Details");
    auto *form = new QFormLayout(gb);
    m_iconLabel = new QLabel;
    m_iconLabel->setAlignment(Qt::AlignCenter);
    m_idLabel = new QLabel;
    m_typeLabel = new QLabel;
    m_statusLabel = new QLabel;
    m_powerLabel = new QLabel;
    m_signalLabel = new QLabel;
    m_consumptionLabel = new QLabel;
    m_toggleBtn = new QPushButton("Toggle");
    m_powerBtn = new QPushButton("Power");
    m_deleteBtn = new QPushButton("Delete");
    m_deleteBtn->setStyleSheet("QPushButton { color: #f44336; }");

    form->addRow(m_iconLabel);
    form->addRow("ID:", m_idLabel);
    form->addRow("Type:", m_typeLabel);
    form->addRow("Status:", m_statusLabel);
    form->addRow("Power:", m_powerLabel);
    form->addRow("Signal:", m_signalLabel);
    form->addRow("Consumption:", m_consumptionLabel);
    form->addRow(m_toggleBtn);
    form->addRow(m_powerBtn);
    form->addRow(m_deleteBtn);
    mainLay->addWidget(gb);
    mainLay->addStretch();

    connect(m_toggleBtn, &QPushButton::clicked, this, [this]() { if (!m_idLabel->text().isEmpty()) emit toggleRequested(m_idLabel->text()); });
    connect(m_powerBtn, &QPushButton::clicked, this, [this]() { if (!m_idLabel->text().isEmpty()) emit powerRequested(m_idLabel->text()); });
    connect(m_deleteBtn, &QPushButton::clicked, this, [this]() { if (!m_idLabel->text().isEmpty()) emit deleteRequested(m_idLabel->text()); });

    setStyleSheet("QGroupBox { color: #0af; font-weight: bold; border: 1px solid #1a3a6b; border-radius: 4px; margin-top: 1ex; padding: 10px; } "
                  "QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 5px; } "
                  "QLabel { color: #c8d8f0; } "
                  "QPushButton { background: #1a3a6b; color: #c8d8f0; border: 1px solid #2a5a9b; border-radius: 4px; padding: 6px 16px; min-width: 80px; } "
                  "QPushButton:hover { background: #2a5a9b; }");
}

void DevicePanel::showDevice(const Device &dev) {
    QMap<QString,QString> icons = {{"lamp","💡"},{"traffic","🚦"},{"sensor","📡"},{"camera","📷"},{"gateway","🔌"},{"sign","⚠️"}};
    m_iconLabel->setText(icons.value(dev.icon, "💡"));
    m_iconLabel->setStyleSheet("font-size: 32px;");
    m_idLabel->setText(dev.id);
    m_typeLabel->setText(dev.deviceType);
    m_statusLabel->setText(dev.statusLabel());
    m_statusLabel->setStyleSheet("color: " + dev.statusColor().name() + "; font-weight: bold;");
    m_powerLabel->setText(dev.powered ? "✅ ON" : "⛔ OFF");
    m_signalLabel->setText(QString::number(dev.signal, 'f', 1) + " dBm");
    m_consumptionLabel->setText(QString::number(dev.consumption, 'f', 2) + " W");
    m_toggleBtn->setEnabled(true);
    m_powerBtn->setEnabled(true);
    m_deleteBtn->setEnabled(true);
}

void DevicePanel::clear() {
    m_iconLabel->clear(); m_idLabel->clear(); m_typeLabel->clear(); m_statusLabel->clear();
    m_powerLabel->clear(); m_signalLabel->clear(); m_consumptionLabel->clear();
    m_toggleBtn->setEnabled(false); m_powerBtn->setEnabled(false); m_deleteBtn->setEnabled(false);
}
