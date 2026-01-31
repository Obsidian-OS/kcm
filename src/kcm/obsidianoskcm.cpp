#include "obsidianoskcm.h"
#include "backupmanager.h"
#include "slotmanager.h"
#include "updatemanager.h"
#include "environmentmanager.h"

#include <KPluginFactory>
#include <QProcess>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

K_PLUGIN_CLASS_WITH_JSON(ObsidianOSKCM, "../../kcm_obsidianos.json")

ObsidianOSKCM::ObsidianOSKCM(QObject *parent, const KPluginMetaData &data)
    : KQuickManagedConfigModule(parent, data)
    , m_backupManager(new BackupManager(this))
    , m_slotManager(new SlotManager(this))
    , m_updateManager(new UpdateManager(this))
    , m_environmentManager(new EnvironmentManager(this))
    , m_obsidianctlAvailable(false)
{
    setButtons(Help);
    checkObsidianctl();
    loadSystemInfo();

    connect(m_backupManager, &BackupManager::errorOccurred, this, &ObsidianOSKCM::errorOccurred);
    connect(m_backupManager, &BackupManager::operationSucceeded, this, &ObsidianOSKCM::infoMessage);
    connect(m_slotManager, &SlotManager::errorOccurred, this, &ObsidianOSKCM::errorOccurred);
    connect(m_slotManager, &SlotManager::operationSucceeded, this, &ObsidianOSKCM::infoMessage);
    connect(m_updateManager, &UpdateManager::errorOccurred, this, &ObsidianOSKCM::errorOccurred);
    connect(m_updateManager, &UpdateManager::operationSucceeded, this, &ObsidianOSKCM::infoMessage);
    connect(m_environmentManager, &EnvironmentManager::errorOccurred, this, &ObsidianOSKCM::errorOccurred);
    connect(m_environmentManager, &EnvironmentManager::operationSucceeded, this, &ObsidianOSKCM::infoMessage);
}

ObsidianOSKCM::~ObsidianOSKCM()
{
}

BackupManager *ObsidianOSKCM::backupManager() const
{
    return m_backupManager;
}

SlotManager *ObsidianOSKCM::slotManager() const
{
    return m_slotManager;
}

UpdateManager *ObsidianOSKCM::updateManager() const
{
    return m_updateManager;
}

EnvironmentManager *ObsidianOSKCM::environmentManager() const
{
    return m_environmentManager;
}

bool ObsidianOSKCM::obsidianctlAvailable() const
{
    return m_obsidianctlAvailable;
}

QString ObsidianOSKCM::currentSlot() const
{
    return m_currentSlot;
}

QString ObsidianOSKCM::systemVersion() const
{
    return m_systemVersion;
}

void ObsidianOSKCM::refreshSystemInfo()
{
    loadSystemInfo();
}

void ObsidianOSKCM::checkObsidianctl()
{
    QProcess process;
    process.start(QStringLiteral("which"), {QStringLiteral("obsidianctl")});
    process.waitForFinished(3000);
    m_obsidianctlAvailable = (process.exitCode() == 0);

    if (!m_obsidianctlAvailable) {
        Q_EMIT errorOccurred(tr("obsidianctl Not Found"),
            tr("The 'obsidianctl' command was not found. Please ensure ObsidianOS system tools are correctly installed and in your PATH."));
    }
}

void ObsidianOSKCM::loadSystemInfo()
{
    if (!m_obsidianctlAvailable) {
        return;
    }

    QProcess process;
    process.start(QStringLiteral("obsidianctl"), {QStringLiteral("status"), QStringLiteral("--json")});
    process.waitForFinished(5000);

    if (process.exitCode() == 0) {
        QString output = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        QJsonDocument doc = QJsonDocument::fromJson(output.toUtf8());
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            QString newSlot = obj.value(QStringLiteral("current_slot")).toString();
            QString newVersion = obj.value(QStringLiteral("version")).toString();

            if (m_currentSlot != newSlot) {
                m_currentSlot = newSlot;
                Q_EMIT currentSlotChanged();
            }

            if (m_systemVersion != newVersion) {
                m_systemVersion = newVersion;
                Q_EMIT systemVersionChanged();
            }
        }
    } else {
        QProcess fallbackProcess;
        fallbackProcess.start(QStringLiteral("obsidianctl"), {QStringLiteral("current-slot")});
        fallbackProcess.waitForFinished(3000);

        if (fallbackProcess.exitCode() == 0) {
            QString newSlot = QString::fromUtf8(fallbackProcess.readAllStandardOutput()).trimmed();
            if (m_currentSlot != newSlot) {
                m_currentSlot = newSlot;
                Q_EMIT currentSlotChanged();
            }
        }

        QFile versionFile(QStringLiteral("/etc/obsidianos-release"));
        if (versionFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString newVersion = QString::fromUtf8(versionFile.readAll()).trimmed();
            if (m_systemVersion != newVersion) {
                m_systemVersion = newVersion;
                Q_EMIT systemVersionChanged();
            }
            versionFile.close();
        }
    }
}

#include "obsidianoskcm.moc"