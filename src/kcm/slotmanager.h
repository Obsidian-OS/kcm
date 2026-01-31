#pragma once

#include <QObject>
#include <QProcess>
#include <qqmlregistration.h>

class SlotManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(QString currentSlot READ currentSlot NOTIFY currentSlotChanged)

public:
    explicit SlotManager(QObject *parent = nullptr);
    ~SlotManager() override;

    bool busy() const;
    QString output() const;
    QString currentSlot() const;

    Q_INVOKABLE void switchSlot(const QString &slot);
    Q_INVOKABLE void switchOnce(const QString &slot);
    Q_INVOKABLE void syncSlots(const QString &targetSlot);
    Q_INVOKABLE void showSlotDiff();
    Q_INVOKABLE void checkHealth();
    Q_INVOKABLE void refreshCurrentSlot();
    Q_INVOKABLE void clearOutput();

Q_SIGNALS:
    void busyChanged();
    void outputChanged();
    void currentSlotChanged();
    void errorOccurred(const QString &title, const QString &message);
    void operationSucceeded(const QString &title, const QString &message);

private Q_SLOTS:
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessReadyRead();

private:
    void startProcess(const QString &command, const QStringList &args = QStringList(), bool usePolkit = true);

    QProcess *m_process;
    bool m_busy;
    QString m_output;
    QString m_currentSlot;
    QString m_currentOperation;
};