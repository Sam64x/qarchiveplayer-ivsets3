#include "IVZone.h"
#include <qdebug.h>

IVZone::IVZone(QObject *parent, IVZoneConfig config)
    : QObject(parent)
    , _config {config}
{}

int IVZone::setIndex() const { return _config.setIndex; }
void IVZone::setSetIndex(int setIndex)
{
    if (_config.setIndex != setIndex) {
        _config.setIndex = setIndex;
        emit setIndexChanged();
    }
}

QString IVZone::type() const { return _config.type; }
void IVZone::setType(const QString &type)
{
    if (_config.type != type) {
        _config.type = type;
        emit typeChanged();
    }
}

QString IVZone::key2() const { return _config.key2; }
void IVZone::setKey2(const QString &key2)
{
    if (_config.key2 != key2) {
        _config.key2 = key2;
        emit key2Changed();
    }
}

bool IVZone::running() const { return _config.running; }
void IVZone::setRunning(bool running)
{
    if (_config.running != running) {
        _config.running = running;
        emit runningChanged();
    }
}

int IVZone::startXCell() const { return _config.startXCell; }
void IVZone::setStartXCell(int startXCell)
{
    if (_config.startXCell != startXCell) {
        _config.startXCell = startXCell;
        emit startXCellChanged();
    }
}

int IVZone::startYCell() const { return _config.startYCell; }
void IVZone::setStartYCell(int startYCell)
{
    if (_config.startYCell != startYCell) {
        _config.startYCell = startYCell;
        emit startYCellChanged();
    }
}

int IVZone::capturedHorizontalCellCount() const { return _config.capturedHorizontalCellCount; }
void IVZone::setCapturedHorizontalCellCount(int count)
{
    if (_config.capturedHorizontalCellCount != count) {
        _config.capturedHorizontalCellCount = count;
        emit capturedHorizontalCellCountChanged();
    }
}

int IVZone::capturedVerticalCellCount() const { return _config.capturedVerticalCellCount; }
void IVZone::setCapturedVerticalCellCount(int count)
{
    if (_config.capturedVerticalCellCount != count) {
        _config.capturedVerticalCellCount = count;
        emit capturedVerticalCellCountChanged();
    }
}

const IVZone::IVZoneConfig IVZone::config() const
{
    return _config;
}

void IVZone::print() const
{
    const int columnWidth = 35;

    qDebug().noquote() << QString("%1%2%3%4%5%6%7%8")
                              .arg("setIndex", -columnWidth)
                              .arg("startXCell", -columnWidth)
                              .arg("startYCell", -columnWidth)
                              .arg("capturedHorizontalCellCount", -columnWidth)
                              .arg("capturedVerticalCellCount", -columnWidth)
                              .arg("type", -columnWidth)
                              .arg("key2", -columnWidth);

    qDebug().noquote() << QString("%1%2%3%4%5%6%7%8")
                              .arg(_config.setIndex, -columnWidth)
                              .arg(_config.startXCell, -columnWidth)
                              .arg(_config.startYCell, -columnWidth)
                              .arg(_config.capturedHorizontalCellCount, -columnWidth)
                              .arg(_config.capturedVerticalCellCount, -columnWidth)
                              .arg(_config.type, -columnWidth)
                              .arg(_config.key2, -columnWidth);
}
