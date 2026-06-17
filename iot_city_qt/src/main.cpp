#include <QApplication>
#include <QSplashScreen>
#include <QPixmap>
#include <QPainter>
#include <QTimer>
#include "mainwindow.h"
#include "utils/settings.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("IoT-City");
    app.setOrganizationName("IoT-City");
    app.setStyle("Fusion");

    QPixmap splashPix(500, 520);
    splashPix.fill(QColor(4, 12, 24));
    {
        QPainter p(&splashPix);
        p.setRenderHint(QPainter::SmoothPixmapTransform);
        QPixmap icon(":/assets/icon.png");
        if (!icon.isNull()) {
            QPixmap scaled = icon.scaled(220, 220, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            p.drawPixmap(250 - scaled.width()/2, 40, scaled);
        }
        QFont f = app.font(); f.setPixelSize(26); f.setBold(true);
        p.setFont(f); p.setPen(QColor(0, 212, 255));
        p.drawText(QRect(0, 290, 500, 40), Qt::AlignCenter, "IoT City");
        f.setPixelSize(14); f.setBold(false);
        p.setFont(f); p.setPen(QColor(200, 216, 240));
        p.drawText(QRect(0, 330, 500, 30), Qt::AlignCenter, "Desktop Monitor");
        f.setPixelSize(10);
        p.setFont(f); p.setPen(QColor(112, 144, 176));
        p.drawText(QRect(0, 480, 500, 20), Qt::AlignCenter, "v1.0.0");
    }

    QSplashScreen splash(splashPix);
    splash.show();
    app.processEvents();

    MainWindow w;
    QTimer::singleShot(3000, &splash, &QWidget::close);
    QTimer::singleShot(3050, &w, &QWidget::show);

    return app.exec();
}
