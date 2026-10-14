import QtQuick
import "../theme"

Item {
    property string title: ""
    property string kana: ""
    property string note: ""

    Rectangle { anchors.fill: parent; color: Theme.bg }

    Column {
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: kana
            color: Theme.line
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.kanaHero
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: title + " · 规划中"
            color: Theme.text
            font.family: Theme.fontBody
            font.pixelSize: 20
            font.bold: true
        }
        Text {
            width: 320
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: note
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 14
            lineHeight: 1.5
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 16
            text: "MODULE SLOT · 已预留导航入口"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 10
            font.letterSpacing: 2.2
        }
    }
}
