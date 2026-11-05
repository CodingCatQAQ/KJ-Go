import QtQuick
import "../../theme"

Item {
    id: root
    required property int index
    required property string text
    required property string face
    required property string visibility

    readonly property int side: Math.max(1, memoryMatch.side)
    readonly property int gap: memoryMatch.side >= 8 ? 4 : (memoryMatch.side >= 6 ? 6 : 8)
    readonly property int cellW: parent ? Math.floor((parent.width - gap * (side - 1)) / side) : 0
    readonly property int cellH: parent ? Math.floor((parent.height - gap * (side - 1)) / side) : 0
    readonly property bool openFace: visibility === "up"
    readonly property bool matchedHold: openFace && memoryMatch.resolving && memoryMatch.resolveMatched

    function textSize() {
        var count = Math.max(1, root.text ? root.text.length : 1)
        var lines = count > 5 ? 2 : 1
        var perLine = Math.ceil(count / lines)
        var byWidth = (width - 16) / perLine
        var byHeight = (height - (height >= 76 ? 28 : 12)) / lines
        var cap = root.face === "word" ? 36 : 22
        return Math.max(10, Math.min(cap, Math.floor(Math.min(byWidth, byHeight))))
    }

    x: (index % side) * (cellW + gap)
    y: Math.floor(index / side) * (cellH + gap)
    width: cellW
    height: cellH
    opacity: visibility === "cleared" ? 0 : 1

    Behavior on opacity {
        NumberAnimation { duration: 180 }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: root.openFace ? Theme.surface : Theme.muted
        border.width: root.matchedHold ? 2 : 1
        border.color: root.matchedHold ? Theme.accent
                      : (cardHover.hovered && root.visibility === "down" ? Theme.text : Theme.border)

        Rectangle {
            visible: !root.openFace
            anchors.centerIn: parent
            width: Math.max(8, Math.min(14, parent.width * 0.12))
            height: width
            rotation: 45
            color: Theme.line
        }

        Text {
            visible: root.openFace && root.height >= 76
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.face === "word" ? "单词" : "释义"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 10
            font.letterSpacing: 1.6
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.text
            color: Theme.text
            font.family: root.face === "word" ? Theme.fontDisplay : Theme.fontBody
            font.pixelSize: root.textSize()
            font.bold: root.face === "word"
            opacity: root.openFace ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }
    }

    HoverHandler { id: cardHover; enabled: root.visibility === "down" && !memoryMatch.resolving }
    TapHandler {
        enabled: root.visibility === "down" && !memoryMatch.resolving
        onTapped: memoryMatch.flip(root.index)
    }
}
