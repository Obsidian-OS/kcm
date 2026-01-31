#pragma once

#include <KQuickManagedConfigModule>
#include <QObject>
#include <qqmlregistration.h>

#include "backupmanager.h"
#include "slotmanager.h"
#include "updatemanager.h"
#include "environmentmanager.h"

class ObsidianOSKCM : public KQuickManagedConfigModule
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(BackupManager* backupManager READ backupManager CONSTANT)
    Q_PROPERTY(SlotManager* slotManager READ slotManager CONSTANT)
    Q_PROPERTY(UpdateManager* updateManager READ updateManager CONSTANT)
    Q_PROPERTY(EnvironmentManager* environmentManager READ environmentManager CONSTANT)
    Q_PROPERTY(bool obsidianctlAvailable READ obsidianctlAvailable CONSTANT)
    Q_PROPERTY(QString currentSlot READ currentSlot NOTIFY currentSlotChanged)
    Q_PROPERTY(QString systemVersion READ systemVersion NOTIFY systemVersionChanged)

public:
    explicit ObsidianOSKCM(QObject *parent, const KPluginMetaData &data);
    ~ObsidianOSKCM() override;

    BackupManager *backupManager() const;
    SlotManager *slotManager() const;
    UpdateManager *updateManager() const;
    EnvironmentManager *environmentManager() const;

    bool obsidianctlAvailable() const;
    QString currentSlot() const;
    QString systemVersion() const;

    Q_INVOKABLE void refreshSystemInfo();

Q_SIGNALS:
    void currentSlotChanged();
    void systemVersionChanged();
    void errorOccurred(const QString &title, const QString &message);
    void infoMessage(const QString &title, const QString &message);

private:
    void checkObsidianctl();
    void loadSystemInfo();

    BackupManager *m_backupManager;
    SlotManager *m_slotManager;
    UpdateManager *m_updateManager;
    EnvironmentManager *m_environmentManager;
    bool m_obsidianctlAvailable;
    QString m_currentSlot;
    QString m_systemVersion;
};