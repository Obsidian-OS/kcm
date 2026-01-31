#include "slotmanager.h"

SlotManager::SlotManager(QObject *parent)
    : QObject(parent)
    , m_process(nullptr)
    , m_busy(false)
{
    refreshCurrentSlot();
}

SlotManager::~SlotManager()
{
    if (m_process) {
        m_process->kill();
        m_process->waitForFinished();
        delete m_process;
    }
}

bool SlotManager::busy() const
{
    return m_busy;
}

QString SlotManager::output() const
{
    return m_output;
}

QString SlotManager::currentSlot() const
{
    return m_currentSlot;
}

void SlotManager::switchSlot(const QString &slot)
{
    m_currentOperation = QStringLiteral("switch");
    startProcess(QStringLiteral("switch"), {slot});
}

void SlotManager::switchOnce(const QString &slot)
{
    m_currentOperation = QStringLiteral("switch-once");
    startProcess(QStringLiteral("switch-once"), {slot});
}

void SlotManager::syncSlots(const QString &targetSlot)
{
    m_currentOperation = QStringLiteral("sync");
    startProcess(QStringLiteral("sync"), {targetSlot});
}

void SlotManager::showSlotDiff()
{
    m_currentOperation = QStringLiteral("slot-diff");
    startProcess(QStringLiteral("slot-diff"));
}

void SlotManager::checkHealth()
{
    m_currentOperation = QStringLiteral("health-check");
    startProcess(QStringLiteral("health-check"));
}

void SlotManager::refreshCurrentSlot()
{
    QProcess process;
    process.start(QStringLiteral("obsidianctl"), {QStringLiteral("current-slot")});
    process.waitForFinished(3000);

    if (process.exitCode() == 0) {
        QString newSlot = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        if (m_currentSlot != newSlot) {
            m_currentSlot = newSlot;
            Q_EMIT currentSlotChanged();
        }
    }
}

void SlotManager::clearOutput()
{
    m_output.clear();
    Q_EMIT outputChanged();
}

void SlotManager::startProcess(const QString &command, const QStringList &args, bool usePolkit)
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
            if (m_currentOperation == QStringLiteral("switch")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("Slot switch scheduled. Please reboot to apply."));
                refreshCurrentSlot();
            } else if (m_currentOperation == QStringLiteral("switch-once")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("One-time slot switch scheduled for next boot."));
            } else if (m_currentOperation == QStringLiteral("sync")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("Slot synchronization completed successfully!"));
            } else if (m_currentOperation == QStringLiteral("health-check")) {
                m_output += QStringLiteral("\n\nHealth check completed successfully.");
                Q_EMIT outputChanged();
            } else if (m_currentOperation == QStringLiteral("slot-diff")) {
                m_output += QStringLiteral("\n\nSlot comparison completed.");
                Q_EMIT outputChanged();
            }
        } else {
            QString errorMsg = m_output.isEmpty() ? tr("Operation failed with exit code %1").arg(exitCode) : m_output;
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

void SlotManager::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(exitStatus)
}

void SlotManager::onProcessReadyRead()
{
}