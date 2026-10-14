import QtQuick
import "../theme"

Item {
    property string title: ""

    Rectangle { anchors.fill: parent; color: Theme.bg }
    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 40
        text: title
        color: Theme.text
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.title
        font.bold: true
    }
}
