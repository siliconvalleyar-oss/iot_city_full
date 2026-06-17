#include <QApplication>
#include <QSplashScreen>
#include <QPixmap>
#include <QTimer>
#include <QIcon>
#include "mainwindow.h"
#include "utils/settings.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("IoT-City");
    app.setOrganizationName("IoT-City");
    app.setStyle("Fusion");
    app.setWindowIcon(QIcon(":/assets/icon.png"));

    QPixmap raw(":/assets/icon.png");
    QPixmap splashPix = raw.scaled(500, 520, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    QSplashScreen splash(splashPix);
    splash.show();
    app.processEvents();

    MainWindow w;
    QTimer::singleShot(1500, &splash, &QWidget::close);
    QTimer::singleShot(1550, &w, &QWidget::show);

    return app.exec();
}
