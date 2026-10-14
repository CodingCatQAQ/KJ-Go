import QtQuick
import "../theme"

Rectangle {
    id: root
    property alias text: label.text
    implicitWidth: Math.max(20, label.implicitWidth + 12)
    implicitHeight: 20
    radius: 2
    color: "transparent"
    border.width: 1
    border.color: Theme.line

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.textMuted
        font.family: Theme.fontBody
        font.pixelSize: 10
        font.bold: true
    }
}
