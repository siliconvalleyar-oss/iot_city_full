#include "logpanel.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QDateTime>
#include <QJsonDocument>

LogPanel::LogPanel(QWidget *parent) : QWidget(parent) {
    auto *lay = new QVBoxLayout(this);
    m_logView = new QPlainTextEdit;
    m_logView->setReadOnly(true);
    m_logView->setMaximumBlockCount(m_maxLines);
    m_clearBtn = new QPushButton("Clear Logs");
    auto *hlay = new QHBoxLayout;
    hlay->addStretch();
    hlay->addWidget(m_clearBtn);
    lay->addWidget(m_logView);
    lay->addLayout(hlay);
    setStyleSheet("QPlainTextEdit { background: #040c18; color: #0f0; font-family: monospace; font-size: 11px; border: 1px solid #1a3a6b; } "
                  "QPushButton { background: #1a3a6b; color: #c8d8f0; border: 1px solid #2a5a9b; border-radius: 4px; padding: 4px 12px; }");
    connect(m_clearBtn, &QPushButton::clicked, m_logView, &QPlainTextEdit::clear);
}

void LogPanel::addLog(const QJsonObject &msg) {
    QString ts = QDateTime::currentDateTime().toString("HH:mm:ss.zzz");
    QString txt = QJsonDocument(msg).toJson(QJsonDocument::Compact);
    m_logView->appendPlainText(QString("[%1] %2").arg(ts, txt));
}

void LogPanel::clearLogs() { m_logView->clear(); }
