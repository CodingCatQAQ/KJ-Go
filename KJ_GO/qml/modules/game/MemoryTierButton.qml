import QtQuick
import "../../theme"

Rectangle {
    id: root
    property int side: 4
    property string title: ""
    signal picked()

    readonly property int pairCount: (side * side) / 2
    readonly property int cardCount: side * side
    readonly property int pool: memoryMatch.usableCount
    readonly property bool open: pool >= pairCount
    readonly property int lack: Math.max(0, pairCount - pool)

    implicitWidth: 420
    implicitHeight: 76
    width: 420
    height: 76
    radius: Theme.radiusMd
    color: root.open && hover.hovered ? Theme.muted : Theme.surface
    border.width: 1
    border.color: root.open && hover.hovered ? Theme.text : Theme.border
    opacity: root.open ? 1 : 0.5

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Text {
            text: root.title + "  " + root.side + "×" + root.side
            color: Theme.text
            font.family: Theme.fontBody
            font.pixelSize: 16
            font.bold: true
        }
        Text {
            text: root.open
                  ? (root.pairCount + " 对 · " + root.cardCount + " 张")
                  : ("还差 " + root.lack + " 个词")
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 12
        }
    }

    HoverHandler { id: hover; enabled: root.open }
    TapHandler {
        enabled: root.open
        onTapped: root.picked()
    }
}
