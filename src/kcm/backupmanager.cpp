#include "backupmanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

BackupModel::BackupModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int BackupModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_backups.count();
}

QVariant BackupModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_backups.count()) {
        return QVariant();
    }

    const BackupInfo &backup = m_backups.at(index.row());

    switch (role) {
    case PathRole:
        return backup.path;
    case SlotRole:
        return backup.slot;
    case TimestampRole:
        return backup.timestamp;
    case SizeRole:
        return backup.size;
    case SizeStringRole:
        return formatSize(backup.size);
    case IsFullBackupRole:
        return backup.isFullBackup;
    }

    return QVariant();
}

QHash<int, QByteArray> BackupModel::roleNames() const
{
    return {
        {PathRole, "path"},
        {SlotRole, "slot"},
        {TimestampRole, "timestamp"},
        {SizeRole, "size"},
        {SizeStringRole, "sizeString"},
        {IsFullBackupRole, "isFullBackup"}
    };
}

void BackupModel::setBackups(const QList<BackupInfo> &backups)
{
    beginResetModel();
    m_backups = backups;
    endResetModel();
}

void BackupModel::clear()
{
    beginResetModel();
    m_backups.clear();
    endResetModel();
}

BackupInfo BackupModel::backupAt(int index) const
{
    if (index >= 0 && index < m_backups.count()) {
        return m_backups.at(index);
    }
    return BackupInfo();
}

void BackupModel::removeAt(int index)
{
    if (index >= 0 && index < m_backups.count()) {
        beginRemoveRows(QModelIndex(), index, index);
        m_backups.removeAt(index);
        endRemoveRows();
    }
}

QString BackupModel::formatSize(qint64 bytes) const
{
    if (bytes == 0) {
        return QStringLiteral("Unknown");
    }

    const QStringList units = {QStringLiteral("B"), QStringLiteral("KB"), QStringLiteral("MB"), QStringLiteral("GB"), QStringLiteral("TB")};
    double size = bytes;
    int unitIndex = 0;

    while (size >= 1024.0 && unitIndex < units.size() - 1) {
        size /= 1024.0;
        unitIndex++;
    }

    return QStringLiteral("%1 %2").arg(size, 0, 'f', 1).arg(units.at(unitIndex));
}

BackupManager::BackupManager(QObject *parent)
    : QObject(parent)
    , m_model(new BackupModel(this))
    , m_process(nullptr)
    , m_busy(false)
    , m_pendingDeleteIndex(-1)
{
}

BackupManager::~BackupManager()
{
    if (m_process) {
        m_process->kill();
        m_process->waitForFinished();
        delete m_process;
    }
}

BackupModel *BackupManager::model() const
{
    return m_model;
}

bool BackupManager::busy() const
{
    return m_busy;
}

QString BackupManager::output() const
{
    return m_output;
}

void BackupManager::refreshBackups()
{
    parseBackups();
    Q_EMIT refreshFinished();
}

void BackupManager::createBackup(const QString &slot, const QString &customDir, bool fullBackup)
{
    QStringList args;
    args << slot;

    if (!customDir.isEmpty()) {
        args << QStringLiteral("--backup-dir") << customDir;
    }

    if (fullBackup) {
        args << QStringLiteral("--full-backup");
    }

    m_currentOperation = QStringLiteral("create");
    startProcess(QStringLiteral("backup-slot"), args);
}

void BackupManager::restoreBackup(int index, const QString &targetSlot)
{
    BackupInfo backup = m_model->backupAt(index);
    if (backup.path.isEmpty()) {
        Q_EMIT errorOccurred(tr("Error"), tr("Invalid backup selection."));
        return;
    }

    QStringList args;
    args << targetSlot << backup.path;

    m_currentOperation = QStringLiteral("restore");
    startProcess(QStringLiteral("rollback-slot"), args);
}

void BackupManager::deleteBackup(int index)
{
    BackupInfo backup = m_model->backupAt(index);
    if (backup.path.isEmpty()) {
        Q_EMIT errorOccurred(tr("Error"), tr("Invalid backup selection."));
        return;
    }

    if (m_busy) {
        return;
    }

    m_pendingDeleteIndex = index;
    m_currentOperation = QStringLiteral("delete");

    if (m_process) {
        m_process->disconnect();
        m_process->kill();
        m_process->waitForFinished(1000);
        delete m_process;
        m_process = nullptr;
    }

    m_process = new QProcess(this);

    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitStatus)

        m_busy = false;
        Q_EMIT busyChanged();

        if (exitCode == 0) {
            if (m_pendingDeleteIndex >= 0) {
                m_model->removeAt(m_pendingDeleteIndex);
                m_pendingDeleteIndex = -1;
            }
            Q_EMIT operationSucceeded(tr("Success"), tr("Backup deleted successfully!"));
        } else {
            QString errorOutput = QString::fromUtf8(m_process->readAllStandardError()).trimmed();
            if (errorOutput.isEmpty()) {
                errorOutput = tr("Failed to delete backup with exit code %1").arg(exitCode);
            }
            Q_EMIT errorOccurred(tr("Error"), errorOutput);
        }

        m_currentOperation.clear();
        m_pendingDeleteIndex = -1;

        if (m_process) {
            m_process->deleteLater();
            m_process = nullptr;
        }
    });

    connect(m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        m_busy = false;
        Q_EMIT busyChanged();

        QString errorMsg;
        switch (error) {
            case QProcess::FailedToStart:
                errorMsg = tr("Failed to start process. Make sure pkexec is installed.");
                break;
            case QProcess::Crashed:
                errorMsg = tr("Process crashed.");
                break;
            default:
                errorMsg = tr("Unknown process error occurred.");
                break;
        }
        Q_EMIT errorOccurred(tr("Error"), errorMsg);
        m_currentOperation.clear();
        m_pendingDeleteIndex = -1;

        if (m_process) {
            m_process->deleteLater();
            m_process = nullptr;
        }
    });

    m_busy = true;
    Q_EMIT busyChanged();

    m_output.clear();
    Q_EMIT outputChanged();

    QStringList args;
    args << QStringLiteral("rm") << QStringLiteral("-f") << backup.path;
    m_process->start(QStringLiteral("pkexec"), args);
}

void BackupManager::cleanupBackups(int olderThanDays)
{
    QDateTime cutoffTime = QDateTime::currentDateTime().addDays(-olderThanDays);
    int deletedCount = 0;

    for (int i = m_model->rowCount() - 1; i >= 0; i--) {
        BackupInfo backup = m_model->backupAt(i);
        if (backup.timestamp < cutoffTime) {
            QProcess process;
            process.start(QStringLiteral("pkexec"), {QStringLiteral("rm"), QStringLiteral("-f"), backup.path});
            process.waitForFinished(30000);

            if (process.exitCode() == 0) {
                m_model->removeAt(i);
                deletedCount++;
            }
        }
    }

    Q_EMIT operationSucceeded(tr("Cleanup Complete"), tr("Deleted %1 old backups.").arg(deletedCount));
}

QString BackupManager::backupPath(int index) const
{
    return m_model->backupAt(index).path;
}

QString BackupManager::backupSlot(int index) const
{
    return m_model->backupAt(index).slot;
}

QString BackupManager::backupTimestamp(int index) const
{
    return m_model->backupAt(index).timestamp.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
}

QString BackupManager::backupSize(int index) const
{
    return m_model->data(m_model->index(index), BackupModel::SizeStringRole).toString();
}

bool BackupManager::backupIsFullBackup(int index) const
{
    return m_model->backupAt(index).isFullBackup;
}

void BackupManager::startProcess(const QString &command, const QStringList &args, bool usePolkit)
{
    if (m_busy) {
        return;
    }

    if (m_process) {
        m_process->disconnect();
        m_process->kill();
        m_process->waitForFinished(1000);
        delete m_process;
        m_process = nullptr;
    }

    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        if (m_process) {
            QString data = QString::fromUtf8(m_process->readAllStandardOutput());
            if (!data.isEmpty()) {
                m_output += data;
                Q_EMIT outputChanged();
            }
        }
    });

    connect(m_process, &QProcess::readyReadStandardError, this, [this]() {
        if (m_process) {
            QString data = QString::fromUtf8(m_process->readAllStandardError());
            if (!data.isEmpty()) {
                m_output += data;
                Q_EMIT outputChanged();
            }
        }
    });

    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitStatus)

        if (m_process) {
            QString remainingOutput = QString::fromUtf8(m_process->readAllStandardOutput());
            QString remainingError = QString::fromUtf8(m_process->readAllStandardError());

            if (!remainingOutput.isEmpty()) {
                m_output += remainingOutput;
            }
            if (!remainingError.isEmpty()) {
                m_output += remainingError;
            }
            Q_EMIT outputChanged();
        }

        m_busy = false;
        Q_EMIT busyChanged();

        if (exitCode == 0) {
            if (m_currentOperation == QStringLiteral("create")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("Backup created successfully!"));
                refreshBackups();
            } else if (m_currentOperation == QStringLiteral("restore")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("Backup restored successfully!"));
            }
        } else {
            QString errorMsg = m_output.trimmed();
            if (errorMsg.isEmpty()) {
                errorMsg = tr("Operation failed with exit code %1").arg(exitCode);
            }
            Q_EMIT errorOccurred(tr("Error"), errorMsg);
        }

        m_currentOperation.clear();

        if (m_process) {
            m_process->deleteLater();
            m_process = nullptr;
        }
    });

    connect(m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        m_busy = false;
        Q_EMIT busyChanged();

        QString errorMsg;
        switch (error) {
            case QProcess::FailedToStart:
                errorMsg = tr("Failed to start process. Make sure pkexec and obsidianctl are installed.");
                break;
            case QProcess::Crashed:
                errorMsg = tr("Process crashed.");
                break;
            case QProcess::Timedout:
                errorMsg = tr("Process timed out.");
                break;
            default:
                errorMsg = tr("Unknown process error occurred.");
                break;
        }
        Q_EMIT errorOccurred(tr("Error"), errorMsg);
        m_currentOperation.clear();

        if (m_process) {
            m_process->deleteLater();
            m_process = nullptr;
        }
    });

    m_busy = true;
    Q_EMIT busyChanged();

    m_output.clear();
    Q_EMIT outputChanged();

    if (usePolkit) {
        QStringList fullArgs;
        fullArgs << QStringLiteral("obsidianctl") << command << args;
        m_process->start(QStringLiteral("pkexec"), fullArgs);
    } else {
        QStringList fullArgs;
        fullArgs << command << args;
        m_process->start(QStringLiteral("obsidianctl"), fullArgs);
    }
}

void BackupManager::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(exitStatus)
}

void BackupManager::onProcessReadyRead()
{
}

void BackupManager::parseBackups()
{
    QList<BackupInfo> backups;

    QStringList backupDirs = {
        QStringLiteral("/var/backups/obsidianctl/slot_a"),
        QStringLiteral("/var/backups/obsidianctl/slot_b")
    };

    for (const QString &dirPath : backupDirs) {
        QDir dir(dirPath);
        if (!dir.exists()) {
            continue;
        }

        QString slotName = QFileInfo(dirPath).fileName();
        slotName = slotName.mid(5);

        QStringList filters;
        filters << QStringLiteral("*.sfs");
        QFileInfoList files = dir.entryInfoList(filters, QDir::Files, QDir::Time);

        for (const QFileInfo &fileInfo : files) {
            BackupInfo backup;
            backup.path = fileInfo.absoluteFilePath();
            backup.slot = slotName;
            backup.timestamp = fileInfo.lastModified();
            backup.size = fileInfo.size();
            backup.isFullBackup = false;

            QString metadataPath = fileInfo.absolutePath() + QStringLiteral("/") +
                                   fileInfo.completeBaseName() + QStringLiteral(".json");
            QFile metadataFile(metadataPath);
            if (metadataFile.open(QIODevice::ReadOnly)) {
                QJsonDocument doc = QJsonDocument::fromJson(metadataFile.readAll());
                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
                    backup.isFullBackup = obj.value(QStringLiteral("is_full_backup")).toBool(false);
                }
                metadataFile.close();
            }

            backups.append(backup);
        }
    }

    std::sort(backups.begin(), backups.end(), [](const BackupInfo &a, const BackupInfo &b) {
        return a.timestamp > b.timestamp;
    });

    m_model->setBackups(backups);
}