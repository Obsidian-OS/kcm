#pragma once

#include <QObject>
#include <QAbstractListModel>
#include <QDateTime>
#include <QProcess>
#include <qqmlregistration.h>

struct BackupInfo {
    QString path;
    QString slot;
    QDateTime timestamp;
    qint64 size;
    bool isFullBackup;
};

class BackupModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        PathRole = Qt::UserRole + 1,
        SlotRole,
        TimestampRole,
        SizeRole,
        SizeStringRole,
        IsFullBackupRole
    };

    explicit BackupModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setBackups(const QList<BackupInfo> &backups);
    void clear();
    BackupInfo backupAt(int index) const;
    void removeAt(int index);

private:
    QString formatSize(qint64 bytes) const;
    QList<BackupInfo> m_backups;
};

class BackupManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(BackupModel* model READ model CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)

public:
    explicit BackupManager(QObject *parent = nullptr);
    ~BackupManager() override;

    BackupModel *model() const;
    bool busy() const;
    QString output() const;

    Q_INVOKABLE void refreshBackups();
    Q_INVOKABLE void createBackup(const QString &slot, const QString &customDir = QString(), bool fullBackup = false);
    Q_INVOKABLE void restoreBackup(int index, const QString &targetSlot);
    Q_INVOKABLE void deleteBackup(int index);
    Q_INVOKABLE void cleanupBackups(int olderThanDays);
    Q_INVOKABLE QString backupPath(int index) const;
    Q_INVOKABLE QString backupSlot(int index) const;
    Q_INVOKABLE QString backupTimestamp(int index) const;
    Q_INVOKABLE QString backupSize(int index) const;
    Q_INVOKABLE bool backupIsFullBackup(int index) const;

Q_SIGNALS:
    void busyChanged();
    void outputChanged();
    void errorOccurred(const QString &title, const QString &message);
    void operationSucceeded(const QString &title, const QString &message);
    void refreshFinished();

private Q_SLOTS:
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessReadyRead();

private:
    void startProcess(const QString &command, const QStringList &args, bool usePolkit = true);
    void parseBackups();

    BackupModel *m_model;
    QProcess *m_process;
    bool m_busy;
    QString m_output;
    QString m_currentOperation;
    int m_pendingDeleteIndex;
};