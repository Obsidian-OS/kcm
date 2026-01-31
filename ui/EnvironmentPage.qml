import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: environmentPage

    required property var environmentManager

    property bool wideMode: width > Kirigami.Units.gridUnit * 35

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: qsTr("Slot Environment")
            level: 2
        }

        Item { Layout.fillWidth: true }

        QQC2.BusyIndicator {
            running: environmentManager.busy
            visible: environmentManager.busy
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
            title: qsTr("Enter Slot Environment")
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
                    id: chrootSlotCombo
                    model: ["a", "b"]
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("Mount options:")
                    Layout.alignment: Qt.AlignTop
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.CheckBox {
                        id: mountEssentialsCheck
                        text: qsTr("Mount essentials (/proc, /sys, /dev)")
                        checked: environmentManager.mountEssentials
                        onToggled: environmentManager.mountEssentials = checked
                    }

                    QQC2.CheckBox {
                        id: enableNetworkingCheck
                        text: qsTr("Enable networking")
                        checked: environmentManager.enableNetworking
                        onToggled: environmentManager.enableNetworking = checked
                    }

                    QQC2.CheckBox {
                        id: mountHomeCheck
                        text: qsTr("Mount /home")
                        checked: environmentManager.mountHome
                        onToggled: environmentManager.mountHome = checked
                    }

                    QQC2.CheckBox {
                        id: mountRootCheck
                        text: qsTr("Mount /root")
                        checked: environmentManager.mountRoot
                        onToggled: environmentManager.mountRoot = checked
                    }
                }

                QQC2.Button {
                    text: qsTr("Open Terminal in Slot")
                    icon.name: "utilities-terminal"
                    enabled: !environmentManager.busy
                    onClicked: environmentManager.enterSlot(chrootSlotCombo.currentText)
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
            }
        }

        QQC2.GroupBox {
            title: qsTr("Integrity Verification")
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
                    id: verifySlotCombo
                    model: ["a", "b"]
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: qsTr("Check the integrity of the slot's filesystem and verify that all system files are intact.")
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    text: qsTr("Verify Integrity")
                    icon.name: "document-encrypted"
                    enabled: !environmentManager.busy
                    onClicked: {
                        environmentManager.clearOutput()
                        environmentManager.verifyIntegrity(verifySlotCombo.currentText)
                    }
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
            text: qsTr("Output")
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        QQC2.ToolButton {
            icon.name: "edit-clear"
            text: qsTr("Clear")
            display: QQC2.AbstractButton.TextBesideIcon
            enabled: environmentManager.output !== ""
            onClicked: environmentManager.clearOutput()
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
            text: environmentManager.output
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
                visible: environmentManager.output === "" && !environmentManager.busy
                text: qsTr("No output")
                explanation: qsTr("Run a command to see output here")
                icon.name: "utilities-terminal"
            }
        }
    }
}
