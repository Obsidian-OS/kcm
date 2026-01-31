import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: slotsPage

    required property var slotManager

    property bool wideMode: width > Kirigami.Units.gridUnit * 35

    spacing: Kirigami.Units.smallSpacing

    Component.onCompleted: {
        slotManager.refreshCurrentSlot()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: qsTr("Slot Management")
            level: 2
        }

        Item { Layout.fillWidth: true }

        QQC2.Label {
            text: qsTr("Current: Slot %1").arg(slotManager.currentSlot ? slotManager.currentSlot.toUpperCase() : "?")
            font.bold: true
        }

        QQC2.BusyIndicator {
            running: slotManager.busy
            visible: slotManager.busy
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: wideMode ? 2 : 1
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        QQC2.GroupBox {
            title: qsTr("Slot Switching")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: qsTr("Target slot:")
                }

                QQC2.ComboBox {
                    id: switchSlotCombo
                    model: ["a", "b"]
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    text: qsTr("Switch Active Slot")
                    icon.name: "system-switch-user"
                    enabled: !slotManager.busy
                    onClicked: switchConfirmDialog.open()
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    text: qsTr("Switch Once (Next Boot Only)")
                    icon.name: "go-next"
                    enabled: !slotManager.busy
                    onClicked: switchOnceConfirmDialog.open()
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
            }
        }

        QQC2.GroupBox {
            title: qsTr("Slot Synchronization")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: qsTr("Target slot:")
                }

                QQC2.ComboBox {
                    id: syncSlotCombo
                    model: ["a", "b"]
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    text: qsTr("Sync Current to Target")
                    icon.name: "folder-sync"
                    enabled: !slotManager.busy
                    onClicked: syncConfirmDialog.open()
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
            }
        }

        QQC2.GroupBox {
            title: qsTr("Slot Analysis")
            Layout.fillWidth: true
            Layout.columnSpan: wideMode ? 2 : 1
            Layout.alignment: Qt.AlignTop

            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: qsTr("Show Slot Differences")
                    icon.name: "document-edit-verify"
                    enabled: !slotManager.busy
                    onClicked: {
                        slotManager.clearOutput()
                        slotManager.showSlotDiff()
                    }
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    text: qsTr("Check Slot Health")
                    icon.name: "dialog-ok-apply"
                    enabled: !slotManager.busy
                    onClicked: {
                        slotManager.clearOutput()
                        slotManager.checkHealth()
                    }
                    Layout.fillWidth: true
                }
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true

        QQC2.Label {
            text: qsTr("Command Output")
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        QQC2.ToolButton {
            icon.name: "edit-clear"
            text: qsTr("Clear")
            display: QQC2.AbstractButton.TextBesideIcon
            enabled: slotManager.output !== ""
            onClicked: slotManager.clearOutput()
        }
    }

    QQC2.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        QQC2.TextArea {
            id: outputArea
            readOnly: true
            wrapMode: TextEdit.Wrap
            font.family: "monospace"
            text: slotManager.output
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
            }

            onTextChanged: {
                cursorPosition = text.length
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                visible: slotManager.output === "" && !slotManager.busy
                text: qsTr("No output")
                explanation: qsTr("Run a command to see output here")
                icon.name: "utilities-terminal"
            }
        }
    }

    QQC2.Dialog {
        id: switchConfirmDialog
        title: qsTr("Confirm Slot Switch")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)

        onAccepted: {
            slotManager.switchSlot(switchSlotCombo.currentText)
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
                    text: qsTr("Switch active slot to %1?").arg(switchSlotCombo.currentText.toUpperCase())
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("This change will take effect on the next reboot.")
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    QQC2.Dialog {
        id: switchOnceConfirmDialog
        title: qsTr("Confirm One-Time Switch")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)

        onAccepted: {
            slotManager.switchOnce(switchSlotCombo.currentText)
        }

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: "dialog-information"
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                Layout.alignment: Qt.AlignTop
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: qsTr("Boot into slot %1 once?").arg(switchSlotCombo.currentText.toUpperCase())
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("The system will return to the current slot after the next reboot.")
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    QQC2.Dialog {
        id: syncConfirmDialog
        title: qsTr("Confirm Slot Sync")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)

        onAccepted: {
            slotManager.syncSlots(syncSlotCombo.currentText)
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
                    text: qsTr("Sync current slot to slot %1?").arg(syncSlotCombo.currentText.toUpperCase())
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("This will overwrite slot %1 with the contents of the current slot. This operation cannot be undone.").arg(syncSlotCombo.currentText.toUpperCase())
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
