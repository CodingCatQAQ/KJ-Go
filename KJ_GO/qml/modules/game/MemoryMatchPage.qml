import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    property string setId: "ja-vocab"
    signal openVocab()

    function clockText(total) {
        var minutes = Math.floor(total / 60)
        var secs = total % 60
        return minutes + ":" + (secs < 10 ? "0" : "") + secs
    }

    Binding {
        target: memoryMatch
        property: "setId"
        value: root.setId
        restoreMode: Binding.RestoreNone
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    MemorySetup {
        anchors.fill: parent
        visible: memoryMatch.phase === "setup"
        onOpenVocab: root.openVocab()
    }

    Item {
        anchors.fill: parent
        visible: memoryMatch.phase === "playing"

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: memoryMatch.side >= 8 ? 20 : 36
            anchors.rightMargin: memoryMatch.side >= 8 ? 20 : 36
            anchors.topMargin: 24
            anchors.bottomMargin: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: memoryMatch.side + "×" + memoryMatch.side
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 12
                    font.letterSpacing: 1.4
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "剩余 " + memoryMatch.pairsLeft
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Item { width: 20; height: 1 }
                Text {
                    text: "步数 " + memoryMatch.moves
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Item { width: 20; height: 1 }
                Text {
                    text: root.clockText(memoryMatch.seconds)
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    font.bold: true
                }
                Item { width: 28; height: 1 }
                Text {
                    text: "结束"
                    color: endHover.hovered ? Theme.text : Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    HoverHandler { id: endHover }
                    TapHandler { onTapped: memoryMatch.endRound() }
                }
            }

            MemoryBoard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    MemoryResult {
        anchors.fill: parent
        visible: memoryMatch.phase === "finished"
        onAgain: memoryMatch.again()
        onReplay: memoryMatch.replay()
    }
}
