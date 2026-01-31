#pragma once

#include <QObject>
#include <QProcess>
#include <qqmlregistration.h>

class EnvironmentManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(bool enableNetworking READ enableNetworking WRITE setEnableNetworking NOTIFY enableNetworkingChanged)
    Q_PROPERTY(bool mountEssentials READ mountEssentials WRITE setMountEssentials NOTIFY mountEssentialsChanged)
    Q_PROPERTY(bool mountHome READ mountHome WRITE setMountHome NOTIFY mountHomeChanged)
    Q_PROPERTY(bool mountRoot READ mountRoot WRITE setMountRoot NOTIFY mountRootChanged)

public:
    explicit EnvironmentManager(QObject *parent = nullptr);
    ~EnvironmentManager() override;

    bool busy() const;
    QString output() const;
    bool enableNetworking() const;
    bool mountEssentials() const;
    bool mountHome() const;
    bool mountRoot() const;

    void setEnableNetworking(bool enabled);
    void setMountEssentials(bool enabled);
    void setMountHome(bool enabled);
    void setMountRoot(bool enabled);

    Q_INVOKABLE void enterSlot(const QString &slot);
    Q_INVOKABLE void verifyIntegrity(const QString &slot);
    Q_INVOKABLE void clearOutput();

Q_SIGNALS:
    void busyChanged();
    void outputChanged();
    void enableNetworkingChanged();
    void mountEssentialsChanged();
    void mountHomeChanged();
    void mountRootChanged();
    void errorOccurred(const QString &title, const QString &message);
    void operationSucceeded(const QString &title, const QString &message);

private Q_SLOTS:
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessReadyRead();

private:
    void startProcess(const QString &command, const QStringList &args, bool usePolkit = true);

    QProcess *m_process;
    bool m_busy;
    QString m_output;
    QString m_currentOperation;
    bool m_enableNetworking;
    bool m_mountEssentials;
    bool m_mountHome;
    bool m_mountRoot;
};