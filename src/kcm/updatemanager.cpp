#include "updatemanager.h"

#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>

UpdateManager::UpdateManager(QObject *parent)
    : QObject(parent)
    , m_process(nullptr)
    , m_busy(false)
    , m_breakSystemEnabled(false)
{
}

UpdateManager::~UpdateManager()
{
    if (m_process) {
        m_process->kill();
        m_process->waitForFinished();
        delete m_process;
    }
}

bool UpdateManager::busy() const
{
    return m_busy;
}

QString UpdateManager::output() const
{
    return m_output;
}

bool UpdateManager::breakSystemEnabled() const
{
    return m_breakSystemEnabled;
}

void UpdateManager::setBreakSystemEnabled(bool enabled)
{
    if (m_breakSystemEnabled != enabled) {
        m_breakSystemEnabled = enabled;
        Q_EMIT breakSystemEnabledChanged();
    }
}

void UpdateManager::updateFromFile(const QString &slot, const QString &imagePath)
{
    if (!validateImagePath(imagePath)) {
        Q_EMIT errorOccurred(tr("Error"), tr("Please select a valid system image file."));
        return;
    }

    m_currentOperation = QStringLiteral("update");
    startProcess(QStringLiteral("update"), {slot, imagePath});
}

void UpdateManager::networkUpdate(const QString &slot)
{
    m_currentOperation = QStringLiteral("netupdate");

    QStringList args;
    args << slot;

    if (m_breakSystemEnabled) {
        args << QStringLiteral("--break-system");
    }

    startProcess(QStringLiteral("netupdate"), args);
}

void UpdateManager::clearOutput()
{
    m_output.clear();
    Q_EMIT outputChanged();
}

bool UpdateManager::validateImagePath(const QString &path)
{
    if (path.isEmpty()) {
        return false;
    }

    QFileInfo fileInfo(path);
    return fileInfo.exists() && fileInfo.isFile();
}

void UpdateManager::startProcess(const QString &command, const QStringList &args, bool usePolkit)
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

                QRegularExpression re(QStringLiteral("(\\d+)%"));
                QRegularExpressionMatch match = re.match(data);
                if (match.hasMatch()) {
                    int percent = match.captured(1).toInt();
                    Q_EMIT updateProgress(percent);
                }
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
            if (m_currentOperation == QStringLiteral("update")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("System update completed successfully!"));
            } else if (m_currentOperation == QStringLiteral("netupdate")) {
                Q_EMIT operationSucceeded(tr("Success"), tr("Network update completed successfully!"));
            }
        } else {
            QString errorMsg = m_output.trimmed();
            if (errorMsg.isEmpty()) {
                errorMsg = tr("Update failed with exit code %1").arg(exitCode);
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

void UpdateManager::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(exitStatus)
}

void UpdateManager::onProcessReadyRead()
{
}