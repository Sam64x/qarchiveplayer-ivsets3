#include "PrimitiveOverlay.h"

#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGNode>
#include <QtMath>

PrimitiveOverlay::PrimitiveOverlay(QQuickItem* parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    setAntialiasing(true);
}

void PrimitiveOverlay::setPrimitives(const QVariantList& prims)
{
    if (m_rawPrimitives == prims)
        return;

    m_rawPrimitives = prims;
    rebuildGeometry();
    emit primitivesChanged();
    update();
}

void PrimitiveOverlay::geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry)
{
    QQuickItem::geometryChanged(newGeometry, oldGeometry);
    m_geometryDirty = true;
    update();
}

QColor PrimitiveOverlay::parseColor(const QVariant& v, const QColor& fallback)
{
    if (v.canConvert<QColor>()) {
        QColor c = v.value<QColor>();
        if (c.isValid())
            return c;
    }

    if (v.type() == QVariant::String) {
        const QColor c(v.toString());
        if (c.isValid())
            return c;
    }

    return fallback;
}

void PrimitiveOverlay::rebuildGeometry()
{
    m_primitives.clear();

    for (const QVariant& pv : m_rawPrimitives) {
        const QVariantMap obj = pv.toMap();
        const QVariantList ptsVar = obj.value(QStringLiteral("points")).toList();
        if (ptsVar.size() < 2)
            continue;

        RenderPrimitive prim;
        prim.color = parseColor(obj.value(QStringLiteral("color")), QColor("#FFFF0000"));
        prim.thickness = qMax<float>(0.5f, obj.value(QStringLiteral("thickness")).toFloat());
        prim.points.reserve(ptsVar.size());

        for (const QVariant& pointVal : ptsVar) {
            const QVariantMap p = pointVal.toMap();
            const double x = p.value(QStringLiteral("x")).toDouble();
            const double y = p.value(QStringLiteral("y")).toDouble();
            prim.points.append(QPointF(x, y));
        }

        if (prim.valid())
            m_primitives.append(prim);
    }

    m_geometryDirty = true;
}

QSGNode* PrimitiveOverlay::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*)
{
    if (!isVisible() || m_primitives.isEmpty()) {
        delete oldNode;
        return nullptr;
    }

    QSGNode* root = oldNode;
    if (m_geometryDirty) {
        delete root;
        root = nullptr;
        m_geometryDirty = false;
    }

    if (!root)
        root = new QSGNode();

    const int required = m_primitives.size();

    // Ensure enough child nodes
    for (int i = root->childCount(); i < required; ++i)
        root->appendChildNode(new QSGGeometryNode());

    // Remove extra nodes
    while (root->childCount() > required) {
        QSGNode* ch = root->lastChild();
        root->removeChildNode(ch);
        delete ch;
    }

    const float w = static_cast<float>(width());
    const float h = static_cast<float>(height());

    for (int i = 0; i < required; ++i) {
        auto* node = static_cast<QSGGeometryNode*>(root->childAtIndex(i));
        const RenderPrimitive& prim = m_primitives.at(i);

        QSGGeometry* geom = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), prim.points.size());
        geom->setDrawingMode(QSGGeometry::DrawLineStrip);
        geom->setLineWidth(prim.thickness);
        geom->setVertexDataPattern(QSGGeometry::StaticPattern);

        QSGGeometry::Point2D* verts = geom->vertexDataAsPoint2D();
        for (int j = 0; j < prim.points.size(); ++j) {
            const QPointF& p = prim.points.at(j);
            verts[j].set(static_cast<float>(p.x() * w), static_cast<float>((1.0 - p.y()) * h));
        }

        node->setGeometry(geom);
        node->setFlag(QSGNode::OwnsGeometry);

        auto* material = static_cast<QSGFlatColorMaterial*>(node->material());
        if (!material) {
            material = new QSGFlatColorMaterial();
            node->setMaterial(material);
            node->setFlag(QSGNode::OwnsMaterial);
        }
        material->setColor(prim.color);
    }

    return root;
}
