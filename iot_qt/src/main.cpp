#include <QApplication>
#include "mainwindow.h"
#include "utils/settings.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("IoT-City");
    app.setOrganizationName("IoT-City");
    app.setStyle("Fusion");
    MainWindow w;
    w.show();
    return app.exec();
}
