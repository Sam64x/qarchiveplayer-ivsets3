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
    Q_PROPERTY(int generalStatus READ generalStatus NOTIFY generalStatusChanged)
    Q_PROPERTY(int generalProgress READ generalProgress NOTIFY generalProgressChanged)
public:
    enum Roles {
        ControllerRole = Qt::UserRole + 1,
        ClientRole,
        PathRole,
        CameraNameRole,
        TimeTextRole,
        ExportDateRole,
        StatusRole,
        ProgressRole,
        PreviewRole,
        SizeBytesRole
    };

    enum class GeneralStatus {
        Idle = 0,
        Uploading = 1,
        Done = 2,
        Error = 3,
        UploadingAndError = 4
    };

    struct Item {
        QPointer<ExportController> controller;
        QPointer<WebSocketClient> client;
        QString path;
        QString cameraName;
        QString timeText;
        QString exportDate;
        int status {0};
        int progress {0};
        QString preview;
        qint64 sizeBytes {0};
    };

    explicit ExportListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int generalStatus() const;
    void setGeneralStatus(int value);
    int generalProgress() const;
    void setGeneralProgress(int value);

    void addItem(const Item& item);
    void removeItem(int row);
    int indexOfController(const ExportController* controller) const;

    void updatePreview(int row, const QString& preview);
    void updateSizeBytes(int row, qint64 sizeBytes);
    void updateCompletion(int row, int status, int progress, const QString& preview, qint64 sizeBytes);

signals:
    void countChanged();
    void generalStatusChanged();
    void generalProgressChanged();

private:
    void updateGeneralStatus();
    void updateGeneralProgress();

    QVector<Item> m_items;
    int m_generalStatus {0};
    int m_generalProgress {0};
};
