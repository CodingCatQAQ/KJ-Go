import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: control
    property bool katakana: false
    signal changed(bool katakana)
    implicitWidth: 152
    implicitHeight: 40
    text: katakana ? "片假名" : "平假名"
    font.family: Theme.fontBody
    font.pixelSize: Theme.body
    contentItem: Row {
        spacing: 0
        anchors.fill: parent
        Text { width: parent.width / 2; height: parent.height; text: "平假名"; color: control.katakana ? Theme.textMuted : Theme.bg; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 13 }
        Text { width: parent.width / 2; height: parent.height; text: "片假名"; color: control.katakana ? Theme.bg : Theme.textMuted; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 13 }
    }
    background: Rectangle {
        radius: Theme.radiusMd
        color: Theme.surface
        border.color: Theme.line
        Rectangle { x: control.katakana ? parent.width / 2 : 0; width: parent.width / 2; height: parent.height; radius: Theme.radiusMd; color: Theme.primary; Behavior on x { NumberAnimation { duration: Theme.durFast } } }
    }
    onClicked: { katakana = !katakana; changed(katakana) }
}
