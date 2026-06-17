#include "mapwidget.h"
#include <QPainter>
#include <QRadialGradient>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QtMath>
#include <QDateTime>

static const QMap<QString, QString> icons = {
    {"lamp","💡"}, {"traffic","🚦"}, {"sensor","📡"},
    {"camera","📷"}, {"gateway","🔌"}, {"sign","⚠️"}
};

MapWidget::MapWidget(QWidget *parent) : QWidget(parent) {
    setMouseTracking(true);
    setMinimumSize(400, 300);
    m_animTimer = new QTimer(this);
    m_animTimer->setInterval(50);
    connect(m_animTimer, &QTimer::timeout, this, [this]() { update(); });
    m_animTimer->start();
}

void MapWidget::setDevices(const QMap<QString, Device> &devices) { m_devices = devices; update(); }
void MapWidget::updateDevice(const Device &dev) { m_devices[dev.id] = dev; update(); }
void MapWidget::removeDevice(const QString &id) { m_devices.remove(id); if (m_selectedId == id) m_selectedId.clear(); update(); }
void MapWidget::setShowMesh(bool v) { m_showMesh = v; update(); }
void MapWidget::setShowLabels(bool v) { m_showLabels = v; update(); }
void MapWidget::setShowCoverage(bool v) { m_showCoverage = v; update(); }

void MapWidget::zoomIn() { QPointF w = screenToWorld(width()/2.0, height()/2.0); m_zoom = qMin(4.0, m_zoom*1.3); m_panX = width()/2.0 - w.x()*m_zoom; m_panY = height()/2.0 - w.y()*m_zoom; update(); }
void MapWidget::zoomOut() { QPointF w = screenToWorld(width()/2.0, height()/2.0); m_zoom = qMax(0.2, m_zoom*0.77); m_panX = width()/2.0 - w.x()*m_zoom; m_panY = height()/2.0 - w.y()*m_zoom; update(); }
void MapWidget::resetView() { m_zoom = 1.0; m_panX = m_panY = 0; update(); }

QPointF MapWidget::worldToScreen(double wx, double wy) const { return {wx*m_zoom + m_panX, wy*m_zoom + m_panY}; }
QPointF MapWidget::screenToWorld(double sx, double sy) const { return {(sx-m_panX)/m_zoom, (sy-m_panY)/m_zoom}; }

QString MapWidget::deviceAt(double wx, double wy) const {
    for (auto it = m_devices.cbegin(); it != m_devices.cend(); ++it) {
        double r = (it->isRouter() ? 14 : 10) * m_zoom;
        double dx = it->x - wx, dy = it->y - wy;
        if (dx*dx + dy*dy < r*r*2.25) return it.key();
    }
    return {};
}

void MapWidget::paintEvent(QPaintEvent *) {
    QPainter p(this);
    p.setRenderHint(QPainter::Antialiasing);
    p.fillRect(rect(), QColor(4, 12, 24));
    p.setPen(QPen(QColor(26, 58, 107, 102), 1));
    static const int streets[] = {120, 235, 350, 465};
    for (int y : streets) { auto s = worldToScreen(0, y), e = worldToScreen(800, y); p.drawLine(QLineF(s, e)); }
    for (int x : streets) { auto s = worldToScreen(x, 0), e = worldToScreen(x, 600); p.drawLine(QLineF(s, e)); }

    if (m_showMesh) {
        QSet<QPair<QString,QString>> seen;
        for (const auto &dev : m_devices) {
            for (const auto &nid : dev.connectedTo) {
                auto key = qMakePair(qMin(dev.id, nid), qMax(dev.id, nid));
                if (seen.contains(key) || !m_devices.contains(nid)) continue;
                seen.insert(key);
                const auto &nb = m_devices[nid];
                auto s = worldToScreen(dev.x, dev.y), e = worldToScreen(nb.x, nb.y);
                bool both = dev.powered && nb.powered;
                p.setPen(QPen(both ? QColor(0,128,255,89) : QColor(85,102,136,51), both ? 1.5*m_zoom : m_zoom, both ? Qt::DashLine : Qt::SolidLine));
                p.drawLine(s, e);
                if (both && dev.isRouter()) {
                    double t = fmod(QDateTime::currentMSecsSinceEpoch()/1500.0, 1.0);
                    p.setBrush(QColor(0,212,255,204));
                    p.setPen(Qt::NoPen);
                    p.drawEllipse(QPointF(s.x()+(e.x()-s.x())*t, s.y()+(e.y()-s.y())*t), 3*m_zoom, 3*m_zoom);
                }
            }
        }
    }

    if (m_showCoverage) {
        for (const auto &dev : m_devices) {
            if (!dev.powered || !dev.isRouter()) continue;
            auto c = worldToScreen(dev.x, dev.y);
            QRadialGradient grad(c, 80*m_zoom);
            grad.setColorAt(0, QColor(0,128,255,40));
            grad.setColorAt(1, QColor(0,128,255,0));
            p.setBrush(grad);
            p.setPen(Qt::NoPen);
            p.drawEllipse(c, 80*m_zoom, 80*m_zoom);
        }
    }

    for (const auto &dev : m_devices) {
        auto s = worldToScreen(dev.x, dev.y);
        bool isSel = dev.id == m_selectedId;
        double r = (dev.isRouter() ? 14 : 10) * m_zoom;
        QColor color = dev.statusColor();

        if (dev.powered) { p.setBrush(color); p.setPen(Qt::NoPen); p.drawEllipse(s, r+6, r+6); }
        p.setBrush(color);
        p.setPen(Qt::NoPen);
        p.drawEllipse(s, r, r);
        if (dev.isRouter()) { p.setBrush(Qt::NoBrush); p.setPen(QPen(color, m_zoom)); p.drawEllipse(s, r+3*m_zoom, r+3*m_zoom); }
        if (isSel) { p.setBrush(Qt::NoBrush); p.setPen(QPen(QColor(0,212,255), 2*m_zoom)); p.drawEllipse(s, r+6*m_zoom, r+6*m_zoom); }

        QFont f = p.font(); f.setPixelSize(qMax(10, (int)(r*1.1))); p.setFont(f);
        QString icon = icons.value(dev.icon, "💡");
        p.drawText(QRectF(s.x()-r, s.y()-r, r*2, r*2), Qt::AlignCenter, icon);

        if (m_showLabels && m_zoom > 0.6) {
            f.setPixelSize(qMax(8, (int)(10*m_zoom))); f.setFamily("monospace"); p.setFont(f);
            p.setPen(QColor(200,216,240,229));
            p.drawText(QRectF(s.x()-50, s.y()+r+3*m_zoom, 100, 16), Qt::AlignCenter, dev.id);
        }
    }
}

void MapWidget::mousePressEvent(QMouseEvent *e) {
    QPointF w = screenToWorld(e->pos().x(), e->pos().y());
    QString hit = deviceAt(w.x(), w.y());
    if (!hit.isEmpty()) { m_draggingDevice = true; m_dragDevId = hit; m_dragStart = e->pos(); m_dragDevOrig = QPointF(m_devices[hit].x, m_devices[hit].y); setCursor(Qt::ClosedHandCursor); }
    else { m_dragging = true; m_dragStart = e->pos(); setCursor(Qt::ClosedHandCursor); }
}

void MapWidget::mouseMoveEvent(QMouseEvent *e) {
    if (m_draggingDevice) {
        QPointF d = e->pos() - m_dragStart;
        m_devices[m_dragDevId].x = m_dragDevOrig.x() + d.x()/m_zoom;
        m_devices[m_dragDevId].y = m_dragDevOrig.y() + d.y()/m_zoom;
        update(); return;
    }
    if (m_dragging) { m_panX += e->pos().x() - m_dragStart.x(); m_panY += e->pos().y() - m_dragStart.y(); m_dragStart = e->pos(); update(); return; }
    QPointF w = screenToWorld(e->pos().x(), e->pos().y());
    setCursor(deviceAt(w.x(), w.y()).isEmpty() ? Qt::ArrowCursor : Qt::PointingHandCursor);
}

void MapWidget::mouseReleaseEvent(QMouseEvent *e) {
    if (m_draggingDevice) {
        auto &dev = m_devices[m_dragDevId];
        emit deviceMoved(m_dragDevId, qRound(dev.x), qRound(dev.y));
        m_draggingDevice = false; m_dragDevId.clear(); setCursor(Qt::ArrowCursor); return;
    }
    if (m_dragging) { m_dragging = false; setCursor(Qt::ArrowCursor); return; }
    QPointF w = screenToWorld(e->pos().x(), e->pos().y());
    QString hit = deviceAt(w.x(), w.y());
    m_selectedId = hit;
    emit deviceSelected(hit);
    update();
}

void MapWidget::wheelEvent(QWheelEvent *e) {
    double f = e->angleDelta().y() > 0 ? 1.1 : 0.9;
    QPointF w = screenToWorld(e->position().x(), e->position().y());
    m_zoom = qBound(0.2, m_zoom*f, 4.0);
    m_panX = e->position().x() - w.x()*m_zoom;
    m_panY = e->position().y() - w.y()*m_zoom;
    update();
}
