import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: Theme.topBarH
    color: Theme.bg
    border.color: Theme.line
    property int currentIndex: 0
    signal navigate(int index)
    signal toggleTheme()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        spacing: 24
        Text { text: "KANA"; color: Theme.primary; font.family: Theme.fontBody; font.pixelSize: 18; font.letterSpacing: 3.2; font.bold: true; Layout.preferredWidth: 176 }
        Repeater {
            model: ["学习", "闪卡", "游戏", "进度"]
            delegate: Button {
                required property string modelData
                required property int index
                text: modelData
                flat: true
                onClicked: root.navigate(index)
                contentItem: Text { text: parent.text; color: index === root.currentIndex ? Theme.primary : Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { color: "transparent" }
            }
        }
        Item { Layout.fillWidth: true }
        Button { text: Theme.dark ? "浅色" : "深色"; flat: true; onClicked: root.toggleTheme(); contentItem: Text { text: parent.text; color: Theme.textMuted; font.pixelSize: 13 } }
        Button { text: "设置"; flat: true; contentItem: Text { text: parent.text; color: Theme.textMuted; font.pixelSize: 13 } }
    }
}
