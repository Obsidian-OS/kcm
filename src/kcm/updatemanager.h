#pragma once

#include <QObject>
#include <QProcess>
#include <qqmlregistration.h>

class UpdateManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(bool breakSystemEnabled READ breakSystemEnabled WRITE setBreakSystemEnabled NOTIFY breakSystemEnabledChanged)

public:
    explicit UpdateManager(QObject *parent = nullptr);
    ~UpdateManager() override;

    bool busy() const;
    QString output() const;
    bool breakSystemEnabled() const;

    void setBreakSystemEnabled(bool enabled);

    Q_INVOKABLE void updateFromFile(const QString &slot, const QString &imagePath);
    Q_INVOKABLE void networkUpdate(const QString &slot);
    Q_INVOKABLE void clearOutput();
    Q_INVOKABLE bool validateImagePath(const QString &path);

Q_SIGNALS:
    void busyChanged();
    void outputChanged();
    void breakSystemEnabledChanged();
    void errorOccurred(const QString &title, const QString &message);
    void operationSucceeded(const QString &title, const QString &message);
    void updateProgress(int percent);

private Q_SLOTS:
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessReadyRead();

private:
    void startProcess(const QString &command, const QStringList &args, bool usePolkit = true);

    QProcess *m_process;
    bool m_busy;
    QString m_output;
    QString m_currentOperation;
    bool m_breakSystemEnabled;
};