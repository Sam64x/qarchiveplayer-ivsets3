#include "ExportListModel.h"

#include "ExportController.h"
#include "WebSocketClient.h"

ExportListModel::ExportListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int ExportListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return m_items.size();
}

QVariant ExportListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return QVariant();

    const Item& item = m_items.at(index.row());
    switch (role) {
    case ControllerRole:
        return QVariant::fromValue(static_cast<QObject*>(item.controller.data()));
    case ClientRole:
        return QVariant::fromValue(static_cast<QObject*>(item.client.data()));
    case PathRole:
        return item.path;
    case CameraNameRole:
        return item.cameraName;
    case TimeTextRole:
        return item.timeText;
    case ExportDateRole:
        return item.exportDate;
    case StatusRole:
        return item.status;
    case ProgressRole:
        return item.progress;
    case PreviewRole:
        return item.preview;
    case SizeBytesRole:
        return item.sizeBytes;
    default:
        break;
    }

    return QVariant();
}

QHash<int, QByteArray> ExportListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[ControllerRole] = "controller";
    roles[ClientRole] = "client";
    roles[PathRole] = "path";
    roles[CameraNameRole] = "cameraName";
    roles[TimeTextRole] = "timeText";
    roles[ExportDateRole] = "exportDate";
    roles[StatusRole] = "status";
    roles[ProgressRole] = "progress";
    roles[PreviewRole] = "preview";
    roles[SizeBytesRole] = "sizeBytes";
    return roles;
}

int ExportListModel::generalStatus() const
{
    return m_generalStatus;
}

void ExportListModel::setGeneralStatus(int value)
{
    if (m_generalStatus != value) {
        m_generalStatus = value;
        emit generalStatusChanged();
    }
}

int ExportListModel::generalProgress() const
{
    return m_generalProgress;
}

void ExportListModel::setGeneralProgress(int value)
{
    if (m_generalProgress != value) {
        m_generalProgress = value;
        emit generalProgressChanged();
    }
}

void ExportListModel::addItem(const Item& item)
{
    beginInsertRows(QModelIndex(), 0, 0);

    m_items.push_front(item);
    const auto controller = item.controller;
    connect(controller, &ExportController::statusChanged, this, &ExportListModel::updateGeneralStatus);
    connect(controller, &ExportController::exportProgressChanged, this, &ExportListModel::updateGeneralProgress);

    endInsertRows();

    emit countChanged();
}

void ExportListModel::removeItem(int row)
{
    if (row < 0 || row >= m_items.size())
        return;

    beginRemoveRows(QModelIndex(), row, row);

    m_items.removeAt(row);
    updateGeneralStatus();

    endRemoveRows();
    emit countChanged();
}

int ExportListModel::indexOfController(const ExportController* controller) const
{
    if (!controller)
        return -1;

    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items.at(i).controller == controller)
            return i;
    }

    return -1;
}

void ExportListModel::updatePreview(int row, const QString& preview)
{
    if (row < 0 || row >= m_items.size())
        return;
    if (m_items[row].preview == preview)
        return;

    m_items[row].preview = preview;
    emit dataChanged(index(row), index(row), {PreviewRole});
}

void ExportListModel::updateSizeBytes(int row, qint64 sizeBytes)
{
    if (row < 0 || row >= m_items.size())
        return;
    if (m_items[row].sizeBytes == sizeBytes)
        return;

    m_items[row].sizeBytes = sizeBytes;
    emit dataChanged(index(row), index(row), {SizeBytesRole});
}

void ExportListModel::updateCompletion(int row, int status, int progress, const QString& preview, qint64 sizeBytes)
{
    if (row < 0 || row >= m_items.size())
        return;

    Item& item = m_items[row];
    item.status = status;
    item.progress = progress;
    item.preview = preview;
    item.sizeBytes = sizeBytes;
    item.controller = nullptr;
    item.client = nullptr;

    emit dataChanged(index(row), index(row), {
        StatusRole,
        ProgressRole,
        PreviewRole,
        SizeBytesRole,
        ControllerRole,
        ClientRole
    });
}

void ExportListModel::updateGeneralStatus()
{
    bool anyItemUploading = false;
    bool anyItemHasError = false;
    for (auto& item: m_items) {
        if (!item.controller) {
            continue;
        }
        if (!anyItemUploading && item.controller->status() == ExportController::Uploading) {
            anyItemUploading = true;
        }
        if (!anyItemHasError && item.controller->status() == ExportController::Error) {
            anyItemHasError = true;
        }
        if (anyItemUploading && anyItemHasError) {
            break;
        }
    }
    if (anyItemUploading && anyItemHasError) {
        setGeneralStatus(static_cast<int>(GeneralStatus::UploadingAndError));
    }
    else if (anyItemUploading) {
        setGeneralStatus(static_cast<int>(GeneralStatus::Uploading));
    }
    else if (anyItemHasError) {
        setGeneralStatus(static_cast<int>(GeneralStatus::Error));
    }
    else {
        setGeneralStatus(static_cast<int>(GeneralStatus::Done));
    }
}

void ExportListModel::updateGeneralProgress()
{
    auto minProgress = 100;
    for (auto& item: m_items) {
        if (item.controller && item.controller->status() == ExportController::Uploading) {
            minProgress = std::min(minProgress, item.controller->exportProgress());
        }
    }
    setGeneralProgress(minProgress);
}
