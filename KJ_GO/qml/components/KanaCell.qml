import QtQuick
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root
    property string kana: "あ"
    property string romaji: "a"
    property string mastery: "new"
    signal activated()
    implicitWidth: 96
    implicitHeight: 70
    radius: Theme.radiusMd
    color: mastery === "mastered" ? Theme.primary : Theme.surface
    border.width: mastery === "mastered" ? 0 : (mastery === "learning" ? 2 : 1)
    border.color: mastery === "learning" ? Theme.accent : Theme.line
    opacity: enabled ? 1 : 0.42
    layer.enabled: hover.hovered
    layer.smooth: true
    transformOrigin: Item.Center

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -7
        text: root.kana
        color: root.mastery === "mastered" ? Theme.bg : Theme.text
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.kanaCell
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 7
        text: root.romaji.toUpperCase()
        color: root.mastery === "mastered" ? Theme.bg : Theme.textMuted
        font.family: Theme.fontBody
        font.pixelSize: 10
        font.letterSpacing: 1.5
    }
    Rectangle {
        visible: root.mastery === "learning"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: Theme.accent
    }
    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
    scale: hover.hovered ? 1.06 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durFast } }
}
