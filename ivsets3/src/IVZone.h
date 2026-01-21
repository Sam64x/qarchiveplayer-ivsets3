#pragma once

#include <QObject>
#include <QString>

class IVZone : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int setIndex READ setIndex WRITE setSetIndex NOTIFY setIndexChanged)

    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString key2 READ key2 WRITE setKey2 NOTIFY key2Changed)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)

    Q_PROPERTY(int startXCell READ startXCell WRITE setStartXCell NOTIFY startXCellChanged)
    Q_PROPERTY(int startYCell READ startYCell WRITE setStartYCell NOTIFY startYCellChanged)
    Q_PROPERTY(int capturedHorizontalCellCount READ capturedHorizontalCellCount WRITE setCapturedHorizontalCellCount NOTIFY capturedHorizontalCellCountChanged)
    Q_PROPERTY(int capturedVerticalCellCount READ capturedVerticalCellCount WRITE setCapturedVerticalCellCount NOTIFY capturedVerticalCellCountChanged)

public:
    struct IVZoneConfig {
        int setIndex;
        QString type { "empty" };
        QString key2;
        bool running { false };
        int startXCell;
        int startYCell;
        int capturedHorizontalCellCount;
        int capturedVerticalCellCount;
    };

    IVZone(QObject *parent, IVZoneConfig config);

    int setIndex() const;
    void setSetIndex(int setIndex);

    QString type() const;
    void setType(const QString &type);

    QString key2() const;
    void setKey2(const QString &key2);

    bool running() const;
    void setRunning(const bool running);

    int startXCell() const;
    void setStartXCell(int startXCell);

    int startYCell() const;
    void setStartYCell(int startYCell);

    int capturedHorizontalCellCount() const;
    void setCapturedHorizontalCellCount(int count);

    int capturedVerticalCellCount() const;
    void setCapturedVerticalCellCount(int count);

    const IVZoneConfig config() const;

    Q_INVOKABLE void print() const;

signals:
    void setIndexChanged();
    void typeChanged();
    void key2Changed();
    void runningChanged();
    void startXCellChanged();
    void startYCellChanged();
    void capturedHorizontalCellCountChanged();
    void capturedVerticalCellCountChanged();

private:
    IVZoneConfig _config;
};
