import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: Theme.topBarH
    color: Theme.bg
    property int currentIndex: 0
    property string language: "ja"
    signal navigate(int index)
    signal toggleLanguage()
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
        anchors.leftMargin: Theme.navInset
        anchors.rightMargin: 24
        spacing: 0

        Row {
            spacing: 28
            Layout.fillHeight: true
            Repeater {
                model: [
                    { label: "学习" },
                    { label: "闪卡" },
                    { label: "游戏" },
                    { label: "进度" }
                ]
                delegate: Item {
                    id: navItem
                    required property var modelData
                    required property int index
                    width: navLabel.implicitWidth
                    height: Theme.topBarH
                    Text {
                        id: navLabel
                        anchors.centerIn: parent
                        text: navItem.modelData.label
                        color: navItem.index === root.currentIndex ? Theme.text : Theme.textMuted
                        font.family: Theme.fontBody
                        font.pixelSize: 14
                        font.bold: navItem.index === root.currentIndex
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

        Rectangle {
            Layout.rightMargin: 12
            Layout.preferredHeight: 36
            implicitWidth: langText.implicitWidth + 20
            radius: Theme.radiusMd
            color: langHover.hovered ? Theme.muted : "transparent"
            Text {
                id: langText
                anchors.centerIn: parent
                text: root.language === "ko" ? "한국어" : "日本語"
                color: root.language === "ko" ? Theme.langKo : (langHover.hovered ? Theme.text : Theme.textMuted)
                font.family: Theme.fontBody
                font.pixelSize: 11
                font.letterSpacing: 1.4
            }
            HoverHandler { id: langHover }
            TapHandler { onTapped: root.toggleLanguage() }
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
