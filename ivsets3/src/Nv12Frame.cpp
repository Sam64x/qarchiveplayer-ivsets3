#include "Nv12Frame.h"
#include <QMetaType>

void Nv12Frame::registerMetaType()
{
    qRegisterMetaType<Nv12Frame>("Nv12Frame");
    qRegisterMetaType<QVector<Nv12Frame>>("QVector<Nv12Frame>");
}
