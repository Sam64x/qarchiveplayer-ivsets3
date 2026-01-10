#pragma once

#include <QAbstractListModel>
#include <QPointer>
#include <QVector>

class ExportController;
class WebSocketClient;

class ExportListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    enum Roles {
        ControllerRole = Qt::UserRole + 1,
        ClientRole,
        PathRole,
        CameraNameRole,
        TimeTextRole,
        ArchiveKey2Role,
        StatusRole,
        ProgressRole,
        PreviewRole,
        SizeBytesRole
    };

    struct Item {
        QPointer<ExportController> controller;
        QPointer<WebSocketClient> client;
        QString path;
        QString cameraName;
        QString timeText;
        QString archiveKey2;
        int status {0};
        int progress {0};
        QString preview;
        qint64 sizeBytes {0};
    };

    explicit ExportListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int addItem(const Item& item);
    void removeItem(int row);
    int indexOfController(const ExportController* controller) const;

    void updatePreview(int row, const QString& preview);
    void updateSizeBytes(int row, qint64 sizeBytes);
    void updateCompletion(int row, int status, int progress, const QString& preview, qint64 sizeBytes);
    void updateController(int row, ExportController* controller, WebSocketClient* client);

signals:
    void countChanged();

private:
    QVector<Item> m_items;
};
