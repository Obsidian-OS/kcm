#include "environmentmanager.h"

#include <QStandardPaths>

EnvironmentManager::EnvironmentManager(QObject *parent)
    : QObject(parent)
    , m_process(nullptr)
    , m_busy(false)
    , m_enableNetworking(false)
    , m_mountEssentials(true)
    , m_mountHome(false)
    , m_mountRoot(false)
{
}

EnvironmentManager::~EnvironmentManager()
{
    if (m_process) {
        m_process->kill();
        m_process->waitForFinished();
        delete m_process;
    }
}

bool EnvironmentManager::busy() const
{
    return m_busy;
}

QString EnvironmentManager::output() const
{
    return m_output;
}

bool EnvironmentManager::enableNetworking() const
{
    return m_enableNetworking;
}

bool EnvironmentManager::mountEssentials() const
{
    return m_mountEssentials;
}

bool EnvironmentManager::mountHome() const
{
    return m_mountHome;
}

bool EnvironmentManager::mountRoot() const
{
    return m_mountRoot;
}

void EnvironmentManager::setEnableNetworking(bool enabled)
{
    if (m_enableNetworking != enabled) {
        m_enableNetworking = enabled;
        Q_EMIT enableNetworkingChanged();
    }
}

void EnvironmentManager::setMountEssentials(bool enabled)
{
    if (m_mountEssentials != enabled) {
        m_mountEssentials = enabled;
        Q_EMIT mountEssentialsChanged();
    }
}

void EnvironmentManager::setMountHome(bool enabled)
{
    if (m_mountHome != enabled) {
        m_mountHome = enabled;
        Q_EMIT mountHomeChanged();
    }
}

void EnvironmentManager::setMountRoot(bool enabled)
{
    if (m_mountRoot != enabled) {
        m_mountRoot = enabled;
        Q_EMIT mountRootChanged();
    }
}

void EnvironmentManager::enterSlot(const QString &slot)
{
    m_currentOperation = QStringLiteral("enter-slot");

    QStringList args;
    args << QStringLiteral("obsidianctl") << QStringLiteral("enter-slot") << slot;

    if (m_enableNetworking) {
        args << QStringLiteral("--enable-networking");
    }
    if (m_mountEssentials) {
        args << QStringLiteral("--mount-essentials");
    }
    if (m_mountHome) {
        args << QStringLiteral("--mount-home");
    }
    if (m_mountRoot) {
        args << QStringLiteral("--mount-root");
    }

    QString terminal = QStandardPaths::findExecutable(QStringLiteral("konsole"));
    if (terminal.isEmpty()) {
        terminal = QStandardPaths::findExecutable(QStringLiteral("xterm"));
    }
    if (terminal.isEmpty()) {
        terminal = QStandardPaths::findExecutable(QStringLiteral("gnome-terminal"));
    }

    if (terminal.isEmpty()) {
        Q_EMIT errorOccurred(tr("Error"), tr("No terminal emulator found. Please install konsole, xterm, or gnome-terminal."));
        return;
    }

    m_output = tr("Opening terminal for slot %1...").arg(slot.toUpper());
    Q_EMIT outputChanged();

    QProcess *terminalProcess = new QProcess(this);
    connect(terminalProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            terminalProcess, &QProcess::deleteLater);

    QStringList terminalArgs;
    if (terminal.contains(QStringLiteral("konsole"))) {
        terminalArgs << QStringLiteral("-e") << QStringLiteral("pkexec") << args;
    } else if (terminal.contains(QStringLiteral("gnome-terminal"))) {
        terminalArgs << QStringLiteral("--") << QStringLiteral("pkexec") << args;
    } else {
        terminalArgs << QStringLiteral("-e") << QStringLiteral("pkexec") << args;
    }

    terminalProcess->start(terminal, terminalArgs);
}

void EnvironmentManager::verifyIntegrity(const QString &slot)
{
    m_currentOperation = QStringLiteral("verify-integrity");
    startProcess(QStringLiteral("verify-integrity"), {slot});
}

void EnvironmentManager::clearOutput()
{
    m_output.clear();
    Q_EMIT outputChanged();
}

void EnvironmentManager::startProcess(const QString &command, const QStringList &args, bool usePolkit)
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
            if (m_currentOperation == QStringLiteral("verify-integrity")) {
                m_output += QStringLiteral("\n\nIntegrity verification completed successfully.");
                Q_EMIT outputChanged();
                Q_EMIT operationSucceeded(tr("Success"), tr("Slot integrity verified successfully."));
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

void EnvironmentManager::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(exitStatus)
}

void EnvironmentManager::onProcessReadyRead()
{
}