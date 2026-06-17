#ifndef MAPWIDGET_H
#define MAPWIDGET_H

#include <QWidget>
#include <QMap>
#include <QPointF>
#include <QTimer>
#include "models/device.h"

class MapWidget : public QWidget {
    Q_OBJECT
public:
    explicit MapWidget(QWidget *parent = nullptr);
    void setDevices(const QMap<QString, Device> &devices);
    void updateDevice(const Device &dev);
    void removeDevice(const QString &id);
    QString selectedDevice() const { return m_selectedId; }
    bool showMesh() const { return m_showMesh; }
    bool showLabels() const { return m_showLabels; }
    bool showCoverage() const { return m_showCoverage; }

signals:
    void deviceSelected(const QString &id);
    void deviceMoved(const QString &id, double x, double y);

public slots:
    void setShowMesh(bool v);
    void setShowLabels(bool v);
    void setShowCoverage(bool v);
    void zoomIn();
    void zoomOut();
    void resetView();

protected:
    void paintEvent(QPaintEvent *) override;
    void mousePressEvent(QMouseEvent *) override;
    void mouseMoveEvent(QMouseEvent *) override;
    void mouseReleaseEvent(QMouseEvent *) override;
    void wheelEvent(QWheelEvent *) override;

private:
    QPointF worldToScreen(double wx, double wy) const;
    QPointF screenToWorld(double sx, double sy) const;
    QString deviceAt(double wx, double wy) const;

    QMap<QString, Device> m_devices;
    QString m_selectedId;
    double m_zoom = 1.0, m_panX = 0, m_panY = 0;
    bool m_dragging = false, m_draggingDevice = false;
    QString m_dragDevId;
    QPointF m_dragStart, m_dragDevOrig;
    bool m_showMesh = true, m_showLabels = true, m_showCoverage = true;
    QTimer *m_animTimer;
    int m_worldW = 800, m_worldH = 600;
};

#endif
