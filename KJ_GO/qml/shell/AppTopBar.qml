import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: Theme.topBarH
    color: Theme.bg
    property int currentIndex: 0
    signal navigate(int index)
    signal toggleTheme()
    signal openSettings()

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 0

        Row {
            spacing: 8
            Layout.preferredWidth: 192
            Text {
                text: "仮名"
                color: Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: 24
                font.bold: true
                anchors.baseline: kanaMark.baseline
            }
            Text {
                id: kanaMark
                text: "KANA"
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.2
            }
        }

        Row {
            spacing: 28
            Layout.leftMargin: 8
            Layout.fillHeight: true
            Repeater {
                model: [
                    { label: "学习", en: "LEARN" },
                    { label: "闪卡", en: "CARDS" },
                    { label: "游戏", en: "GAMES" },
                    { label: "进度", en: "STATS" }
                ]
                delegate: Item {
                    id: navItem
                    required property var modelData
                    required property int index
                    width: navRow.implicitWidth
                    height: Theme.topBarH
                    Row {
                        id: navRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            id: navLabel
                            text: navItem.modelData.label
                            color: navItem.index === root.currentIndex ? Theme.text : Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 14
                            font.bold: navItem.index === root.currentIndex
                        }
                        Text {
                            text: navItem.modelData.en
                            color: navItem.index === root.currentIndex ? Theme.text : Theme.textMuted
                            opacity: 0.6
                            font.family: Theme.fontBody
                            font.pixelSize: 10
                            font.letterSpacing: 1.6
                            anchors.baseline: navLabel.baseline
                        }
                    }
                    Rectangle {
                        visible: navItem.index === root.currentIndex
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 2
                        color: Theme.primary
                    }
                    TapHandler { onTapped: root.navigate(navItem.index) }
                }
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "日本語 · JA"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 11
            font.letterSpacing: 1.4
            Layout.rightMargin: 12
        }

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Theme.radiusMd
            color: themeHover.hovered ? Theme.muted : "transparent"
            Text {
                anchors.centerIn: parent
                text: Theme.dark ? "☀" : "☾"
                color: themeHover.hovered ? Theme.text : Theme.textMuted
                font.pixelSize: 16
            }
            HoverHandler { id: themeHover }
            TapHandler { onTapped: root.toggleTheme() }
        }
        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.leftMargin: 4
            radius: Theme.radiusMd
            color: settingsHover.hovered ? Theme.muted : "transparent"
            Text {
                anchors.centerIn: parent
                text: "⚙"
                color: settingsHover.hovered ? Theme.text : Theme.textMuted
                font.pixelSize: 15
            }
            HoverHandler { id: settingsHover }
            TapHandler { onTapped: root.openSettings() }
        }
    }
}
