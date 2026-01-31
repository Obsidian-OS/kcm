import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: root

    property bool wideMode: width > Kirigami.Units.gridUnit * 40

    Kirigami.InlineMessage {
        id: errorMessage
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        type: Kirigami.MessageType.Error
        visible: false
        showCloseButton: true
    }

    Kirigami.InlineMessage {
        id: infoMessage
        anchors.top: errorMessage.visible ? errorMessage.bottom : parent.top
        anchors.topMargin: errorMessage.visible ? Kirigami.Units.smallSpacing : 0
        anchors.left: parent.left
        anchors.right: parent.right
        type: Kirigami.MessageType.Positive
        visible: false
        showCloseButton: true
    }

    Connections {
        target: kcm
        function onErrorOccurred(title, message) {
            errorMessage.text = "<b>" + title + "</b>: " + message
            errorMessage.visible = true
            infoMessage.visible = false
        }
        function onInfoMessage(title, message) {
            infoMessage.text = "<b>" + title + "</b>: " + message
            infoMessage.visible = true
            errorMessage.visible = false
        }
    }

    Kirigami.InlineMessage {
        id: warningMessage
        anchors.top: infoMessage.visible ? infoMessage.bottom : (errorMessage.visible ? errorMessage.bottom : parent.top)
        anchors.topMargin: (infoMessage.visible || errorMessage.visible) ? Kirigami.Units.smallSpacing : 0
        anchors.left: parent.left
        anchors.right: parent.right
        type: Kirigami.MessageType.Warning
        text: qsTr("The 'obsidianctl' command was not found. Please ensure ObsidianOS system tools are correctly installed.")
        visible: !kcm.obsidianctlAvailable
    }

    ColumnLayout {
        id: mainContent
        anchors.top: warningMessage.visible ? warningMessage.bottom : (infoMessage.visible ? infoMessage.bottom : (errorMessage.visible ? errorMessage.bottom : parent.top))
        anchors.topMargin: (warningMessage.visible || infoMessage.visible || errorMessage.visible) ? Kirigami.Units.largeSpacing : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0
        enabled: kcm.obsidianctlAvailable

        QQC2.ToolBar {
            Layout.fillWidth: true
            visible: !wideMode

            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                QQC2.ToolButton {
                    icon.name: "application-menu"
                    onClicked: navDrawer.open()
                }

                Kirigami.Heading {
                    text: {
                        switch(tabStack.currentIndex) {
                            case 0: return qsTr("Backups")
                            case 1: return qsTr("Slots")
                            case 2: return qsTr("Updates")
                            case 3: return qsTr("Environment")
                            default: return qsTr("ObsidianOS")
                        }
                    }
                    level: 2
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: kcm.currentSlot ? qsTr("Slot %1").arg(kcm.currentSlot.toUpperCase()) : ""
                    opacity: 0.7
                }

                QQC2.ToolButton {
                    icon.name: "view-refresh"
                    onClicked: refreshAll()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            QQC2.Frame {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                Layout.fillHeight: true
                visible: wideMode

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: "obsidianos"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.large
                            Layout.preferredHeight: Kirigami.Units.iconSizes.large
                            Layout.alignment: Qt.AlignHCenter
                        }

                        QQC2.Label {
                            text: qsTr("ObsidianOS")
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                            Layout.alignment: Qt.AlignHCenter
                        }

                        QQC2.Label {
                            text: kcm.currentSlot ? qsTr("Active: Slot %1").arg(kcm.currentSlot.toUpperCase()) : qsTr("Active: Unknown")
                            opacity: 0.7
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            Layout.alignment: Qt.AlignHCenter
                        }

                        QQC2.Label {
                            text: kcm.systemVersion ? kcm.systemVersion : ""
                            opacity: 0.5
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            Layout.alignment: Qt.AlignHCenter
                            visible: kcm.systemVersion !== ""
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }

                    QQC2.ButtonGroup {
                        id: navGroup
                    }

                    Repeater {
                        model: navModel

                        delegate: QQC2.ItemDelegate {
                            Layout.fillWidth: true
                            text: modelData.name
                            icon.name: modelData.icon
                            highlighted: tabStack.currentIndex === modelData.index
                            QQC2.ButtonGroup.group: navGroup
                            onClicked: tabStack.currentIndex = modelData.index
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        text: qsTr("Refresh")
                        icon.name: "view-refresh"
                        onClicked: refreshAll()
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillHeight: true
                visible: wideMode
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    id: tabStack
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing

                    BackupsPage {
                        backupManager: kcm.backupManager
                    }

                    SlotsPage {
                        slotManager: kcm.slotManager
                    }

                    UpdatesPage {
                        updateManager: kcm.updateManager
                    }

                    EnvironmentPage {
                        environmentManager: kcm.environmentManager
                    }
                }
            }
        }
    }

    QQC2.Drawer {
        id: navDrawer
        width: Math.min(Kirigami.Units.gridUnit * 15, root.width * 0.8)
        height: root.height
        edge: Qt.LeftEdge
        modal: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "obsidianos"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                ColumnLayout {
                    spacing: 0

                    QQC2.Label {
                        text: qsTr("ObsidianOS")
                        font.bold: true
                    }

                    QQC2.Label {
                        text: kcm.currentSlot ? qsTr("Slot %1").arg(kcm.currentSlot.toUpperCase()) : qsTr("Unknown")
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Repeater {
                model: navModel

                delegate: QQC2.ItemDelegate {
                    Layout.fillWidth: true
                    text: modelData.name
                    icon.name: modelData.icon
                    highlighted: tabStack.currentIndex === modelData.index
                    onClicked: {
                        tabStack.currentIndex = modelData.index
                        navDrawer.close()
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            QQC2.Button {
                Layout.fillWidth: true
                text: qsTr("Refresh")
                icon.name: "view-refresh"
                onClicked: {
                    refreshAll()
                    navDrawer.close()
                }
            }
        }
    }

    property var navModel: [
        { name: qsTr("Backups"), icon: "folder-backup", index: 0 },
        { name: qsTr("Slots"), icon: "drive-multidisk", index: 1 },
        { name: qsTr("Updates"), icon: "system-software-update", index: 2 },
        { name: qsTr("Environment"), icon: "utilities-terminal", index: 3 }
    ]

    function refreshAll() {
        kcm.refreshSystemInfo()
        kcm.backupManager.refreshBackups()
        kcm.slotManager.refreshCurrentSlot()
    }
}
