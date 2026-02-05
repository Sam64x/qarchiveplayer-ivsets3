#pragma once

#include <QColor>
#include <QQuickItem>
#include <QRectF>
#include <QVariant>
#include <QVector>

class PrimitiveOverlay : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QVariantList primitives READ primitives WRITE setPrimitives NOTIFY primitivesChanged)
    Q_PROPERTY(QRectF contentRect READ contentRect WRITE setContentRect NOTIFY contentRectChanged)

public:
    explicit PrimitiveOverlay(QQuickItem* parent = nullptr);

    QVariantList primitives() const { return m_rawPrimitives; }
    void setPrimitives(const QVariantList& prims);

    QRectF contentRect() const { return m_contentRect; }
    void setContentRect(const QRectF& rect);

signals:
    void primitivesChanged();
    void contentRectChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;
    void geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry) override;

private:
    struct RenderPrimitive {
        QVector<QPointF> points;
        QColor color { Qt::red };
        float thickness { 2.0f };
        bool valid() const { return points.size() >= 2 && thickness > 0.0f && color.isValid(); }
    };

    void rebuildGeometry();
    static QColor parseColor(const QVariant& v, const QColor& fallback);

    QVariantList m_rawPrimitives;
    QVector<RenderPrimitive> m_primitives;
    QRectF m_contentRect;
    bool m_geometryDirty { false };
};
