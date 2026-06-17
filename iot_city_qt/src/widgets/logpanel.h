#ifndef LOGPANEL_H
#define LOGPANEL_H

#include <QWidget>
#include <QPlainTextEdit>
#include <QJsonObject>
#include <QList>
#include <QPushButton>

class LogPanel : public QWidget {
    Q_OBJECT
public:
    explicit LogPanel(QWidget *parent = nullptr);
    void addLog(const QJsonObject &msg);
    void clearLogs();

private:
    QPlainTextEdit *m_logView;
    QPushButton *m_clearBtn;
    int m_maxLines = 500;
};

#endif
