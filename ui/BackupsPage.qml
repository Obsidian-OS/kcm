import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: backupsPage

    required property var backupManager

    property int selectedIndex: -1

    spacing: Kirigami.Units.smallSpacing

    Component.onCompleted: {
        backupManager.refreshBackups()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: qsTr("System Backups")
            level: 2
        }

        Item { Layout.fillWidth: true }

        QQC2.ToolButton {
            icon.name: "list-add"
            text: qsTr("Create Backup")
            display: QQC2.AbstractButton.TextBesideIcon
            onClicked: createBackupDialog.open()
        }

        QQC2.ToolButton {
            icon.name: "edit-clear-history"
            text: qsTr("Cleanup")
            display: QQC2.AbstractButton.TextBesideIcon
            onClicked: cleanupDialog.open()
        }

        QQC2.BusyIndicator {
            running: backupManager.busy
            visible: backupManager.busy
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.fillWidth: true
        height: headerRow.implicitHeight + Kirigami.Units.smallSpacing * 2
        color: Kirigami.Theme.alternateBackgroundColor

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: qsTr("Slot")
                font.bold: true
                Layout.preferredWidth: 60
            }
            QQC2.Label {
                text: qsTr("Type")
                font.bold: true
                Layout.preferredWidth: 80
            }
            QQC2.Label {
                text: qsTr("Date")
                font.bold: true
                Layout.preferredWidth: 150
            }
            QQC2.Label {
                text: qsTr("Size")
                font.bold: true
                Layout.preferredWidth: 80
            }
            QQC2.Label {
                text: qsTr("Path")
                font.bold: true
                Layout.fillWidth: true
            }
        }
    }

    QQC2.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: backupList
            clip: true
            model: backupManager.model

            delegate: Rectangle {
                width: ListView.view.width
                height: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
                color: {
                    if (index === backupsPage.selectedIndex) {
                        return Kirigami.Theme.highlightColor
                    } else if (index % 2 === 0) {
                        return Kirigami.Theme.backgroundColor
                    } else {
                        return Kirigami.Theme.alternateBackgroundColor
                    }
                }

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: model.slot ? model.slot.toUpperCase() : ""
                        Layout.preferredWidth: 60
                        color: index === backupsPage.selectedIndex ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                    QQC2.Label {
                        text: model.isFullBackup ? qsTr("Full") : qsTr("Partial")
                        Layout.preferredWidth: 80
                        color: index === backupsPage.selectedIndex ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                    QQC2.Label {
                        text: model.timestamp ? Qt.formatDateTime(model.timestamp, "yyyy-MM-dd HH:mm") : ""
                        Layout.preferredWidth: 150
                        color: index === backupsPage.selectedIndex ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                    QQC2.Label {
                        text: model.sizeString || ""
                        Layout.preferredWidth: 80
                        color: index === backupsPage.selectedIndex ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                    QQC2.Label {
                        text: model.path || ""
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                        color: index === backupsPage.selectedIndex ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        backupsPage.selectedIndex = index
                    }
                    onDoubleClicked: {
                        backupsPage.selectedIndex = index
                        propertiesDialog.backupIndex = index
                        propertiesDialog.open()
                    }
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                visible: backupList.count === 0 && !backupManager.busy
                text: qsTr("No backups found")
                explanation: qsTr("Create a backup to protect your system")
                icon.name: "folder-backup"

                helpfulAction: Kirigami.Action {
                    text: qsTr("Create Backup")
                    icon.name: "list-add"
                    onTriggered: createBackupDialog.open()
                }
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: backupsPage.selectedIndex >= 0 ? qsTr("Selected: %1").arg(backupManager.backupPath(backupsPage.selectedIndex)) : qsTr("No backup selected")
            opacity: 0.7
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: qsTr("Properties")
            icon.name: "document-properties"
            enabled: backupsPage.selectedIndex >= 0
            onClicked: {
                propertiesDialog.backupIndex = backupsPage.selectedIndex
                propertiesDialog.open()
            }
        }

        QQC2.Button {
            text: qsTr("Restore")
            icon.name: "edit-undo"
            enabled: backupsPage.selectedIndex >= 0
            onClicked: {
                restoreDialog.backupIndex = backupsPage.selectedIndex
                restoreDialog.open()
            }
        }

        QQC2.Button {
            text: qsTr("Delete")
            icon.name: "edit-delete"
            enabled: backupsPage.selectedIndex >= 0
            onClicked: {
                deleteConfirmDialog.backupIndex = backupsPage.selectedIndex
                deleteConfirmDialog.backupPath = backupManager.backupPath(backupsPage.selectedIndex)
                deleteConfirmDialog.open()
            }
        }
    }

    QQC2.Dialog {
        id: createBackupDialog
        title: qsTr("Create New Backup")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 25)

        onAccepted: {
            backupManager.createBackup(
                slotCombo.currentText,
                customDirField.text,
                fullBackupCheck.checked
            )
        }

        onOpened: {
            slotCombo.currentIndex = 0
            customDirField.text = ""
            fullBackupCheck.checked = false
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: qsTr("Slot to backup:")
            }

            QQC2.ComboBox {
                id: slotCombo
                model: ["a", "b"]
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Custom directory:")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.TextField {
                    id: customDirField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Default location")
                }

                QQC2.Button {
                    icon.name: "folder-open"
                    onClicked: folderDialog.open()
                }
            }

            QQC2.Label {
                text: qsTr("Options:")
            }

            QQC2.CheckBox {
                id: fullBackupCheck
                text: qsTr("Full system backup (includes shared partitions)")
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: qsTr("Select Backup Directory")
        onAccepted: {
            customDirField.text = selectedFolder.toString().replace("file://", "")
        }
    }

    QQC2.Dialog {
        id: restoreDialog
        title: qsTr("Restore Backup")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)

        property int backupIndex: -1

        onAccepted: {
            backupManager.restoreBackup(backupIndex, restoreSlotCombo.currentText)
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: "dialog-warning"
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                Layout.rowSpan: 2
            }

            QQC2.Label {
                text: qsTr("Restore this backup to the selected slot?")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("This will overwrite the target slot contents.")
                opacity: 0.7
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Target slot:")
            }

            QQC2.ComboBox {
                id: restoreSlotCombo
                model: ["a", "b"]
                Layout.fillWidth: true
            }
        }
    }

    QQC2.Dialog {
        id: deleteConfirmDialog
        title: qsTr("Delete Backup")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)

        property int backupIndex: -1
        property string backupPath: ""

        onAccepted: {
            backupManager.deleteBackup(backupIndex)
            backupsPage.selectedIndex = -1
        }

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: "dialog-warning"
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                Layout.alignment: Qt.AlignTop
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: qsTr("Are you sure you want to delete this backup?")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: deleteConfirmDialog.backupPath
                    opacity: 0.7
                    font.family: "monospace"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }
    }

    QQC2.Dialog {
        id: propertiesDialog
        title: qsTr("Backup Properties")
        standardButtons: QQC2.Dialog.Ok
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 25)

        property int backupIndex: -1

        GridLayout {
            anchors.fill: parent
            columns: 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: qsTr("Slot:")
                font.bold: true
            }
            QQC2.Label {
                text: propertiesDialog.backupIndex >= 0 ? backupManager.backupSlot(propertiesDialog.backupIndex).toUpperCase() : ""
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Created:")
                font.bold: true
            }
            QQC2.Label {
                text: propertiesDialog.backupIndex >= 0 ? backupManager.backupTimestamp(propertiesDialog.backupIndex) : ""
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Size:")
                font.bold: true
            }
            QQC2.Label {
                text: propertiesDialog.backupIndex >= 0 ? backupManager.backupSize(propertiesDialog.backupIndex) : ""
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Type:")
                font.bold: true
            }
            QQC2.Label {
                text: propertiesDialog.backupIndex >= 0 && backupManager.backupIsFullBackup(propertiesDialog.backupIndex) ? qsTr("Full System Backup") : qsTr("Partial Backup")
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Path:")
                font.bold: true
            }
            QQC2.Label {
                text: propertiesDialog.backupIndex >= 0 ? backupManager.backupPath(propertiesDialog.backupIndex) : ""
                wrapMode: Text.WrapAnywhere
                Layout.fillWidth: true
            }
        }
    }

    QQC2.Dialog {
        id: cleanupDialog
        title: qsTr("Cleanup Old Backups")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)

        onAccepted: {
            backupManager.cleanupBackups(daysSpinBox.value)
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: "edit-clear-history"
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                Layout.rowSpan: 2
            }

            QQC2.Label {
                text: qsTr("Delete backups older than:")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.SpinBox {
                    id: daysSpinBox
                    from: 1
                    to: 365
                    value: 30
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                }

                QQC2.Label {
                    text: qsTr("days")
                }
            }
        }
    }
}
