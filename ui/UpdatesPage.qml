import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: updatesPage

    required property var updateManager

    property bool wideMode: width > Kirigami.Units.gridUnit * 35

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: qsTr("System Updates")
            level: 2
        }

        Item { Layout.fillWidth: true }

        QQC2.BusyIndicator {
            running: updateManager.busy
            visible: updateManager.busy
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
            title: qsTr("Local Update")
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
                    id: localUpdateSlotCombo
                    model: ["a", "b"]
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("Image file:")
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.TextField {
                        id: imagePathField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Select a SquashFS image...")
                        readOnly: true
                    }

                    QQC2.Button {
                        icon.name: "document-open"
                        onClicked: imageFileDialog.open()
                    }
                }

                QQC2.Button {
                    text: qsTr("Apply Local Update")
                    icon.name: "system-software-update"
                    enabled: !updateManager.busy && imagePathField.text !== ""
                    onClicked: localUpdateConfirmDialog.open()
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
            }
        }

        QQC2.GroupBox {
            title: qsTr("Network Update")
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
                    id: netUpdateSlotCombo
                    model: ["a", "b"]
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("Download and install the latest system image from the update server.")
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    text: qsTr("Download && Update")
                    icon.name: "download"
                    enabled: !updateManager.busy
                    onClicked: netUpdateConfirmDialog.open()
                    Layout.columnSpan: 2
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
            text: qsTr("Update Output")
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        QQC2.ToolButton {
            icon.name: "edit-clear"
            text: qsTr("Clear")
            display: QQC2.AbstractButton.TextBesideIcon
            enabled: updateManager.output !== ""
            onClicked: updateManager.clearOutput()
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
            text: updateManager.output
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
                visible: updateManager.output === "" && !updateManager.busy
                text: qsTr("No output")
                explanation: qsTr("Start an update to see progress here")
                icon.name: "system-software-update"
            }
        }
    }

    FileDialog {
        id: imageFileDialog
        title: qsTr("Select System Image")
        nameFilters: [qsTr("SquashFS Files (*.sfs)"), qsTr("All Files (*)")]
        onAccepted: {
            imagePathField.text = selectedFile.toString().replace("file://", "")
        }
    }

    QQC2.Dialog {
        id: localUpdateConfirmDialog
        title: qsTr("Confirm Local Update")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 25)

        onAccepted: {
            updateManager.updateFromFile(localUpdateSlotCombo.currentText, imagePathField.text)
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
                    text: qsTr("Update slot %1 with the selected image?").arg(localUpdateSlotCombo.currentText.toUpperCase())
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("This will overwrite the entire slot contents.")
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: imagePathField.text
                    font.family: "monospace"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.5
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }
    }

    QQC2.Dialog {
        id: netUpdateConfirmDialog
        title: qsTr("Confirm Network Update")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        modal: true
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 25)

        onAccepted: {
            updateManager.networkUpdate(netUpdateSlotCombo.currentText)
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
                    text: qsTr("Download and update slot %1 from the network?").arg(netUpdateSlotCombo.currentText.toUpperCase())
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("The latest system image will be downloaded from the update server and applied to the selected slot.")
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
