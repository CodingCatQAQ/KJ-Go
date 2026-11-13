import QtQuick
import "../../theme"

Item {
    id: root
    required property int index
    required property string label
    required property bool up

    readonly property bool wordFace: whackMole.moleFace === "word"
    readonly property int columns: 3
    readonly property int gap: 16
    readonly property int cellW: parent ? Math.floor((parent.width - gap * (columns - 1)) / columns) : 0
    readonly property int cellH: parent ? Math.floor((parent.height - gap) / 2) : 0

    x: (index % columns) * (cellW + gap)
    y: Math.floor(index / columns) * (cellH + gap)
    width: cellW
    height: cellH

    function textSize() {
        var count = Math.max(1, root.label ? root.label.length : 1)
        var lines = count > 6 ? 2 : 1
        var perLine = Math.ceil(count / lines)
        var byWidth = (width - 28) / perLine
        var byHeight = (height * 0.46) / lines
        var cap = root.wordFace ? 36 : 22
        return Math.max(12, Math.min(cap, Math.floor(Math.min(byWidth, byHeight))))
    }

    clip: true

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: parent.width * 0.62
        height: 16
        radius: 8
        color: Theme.muted
    }

    Rectangle {
        id: card
        width: parent.width - 12
        height: Math.max(64, parent.height * 0.58)
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.up ? parent.height * 0.06 : parent.height * 0.46
        opacity: root.up ? 1 : 0
        radius: Theme.radiusMd
        color: Theme.surface
        border.width: 1
        border.color: holeHover.hovered && root.up ? Theme.text : Theme.border

        Behavior on y {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.label
            color: Theme.text
            font.family: root.wordFace ? Theme.fontDisplay : Theme.fontBody
            font.pixelSize: root.textSize()
            font.bold: root.wordFace
        }

        HoverHandler { id: holeHover; enabled: root.up }
        TapHandler {
            enabled: root.up
            onTapped: whackMole.whack(root.index)
        }
    }
}
