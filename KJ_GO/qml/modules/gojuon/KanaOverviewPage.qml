import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property bool katakana: false
    property string filter: "all"
    property var mastery: ({})
    property string hovered: "a"
    signal openDetail(string romaji)
    signal toggleScript(bool katakana)

    readonly property var entry: KanaCatalog.find(katakana, hovered)
    readonly property var stats: KanaCatalog.counts(mastery)

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 40
        anchors.bottomMargin: 32
        spacing: 28

        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            ColumnLayout {
                spacing: 8
                Text {
                    text: "GOJŪON · 清音"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2.4
                }
                Text {
                    text: "五十音図"
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.title
                    font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            ScriptToggle {
                katakana: root.katakana
                onChanged: root.toggleScript(katakana)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 28

            Flickable {
                id: chartScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: chart.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: chart
                    width: chartScroll.width
                    spacing: 8

                    Row {
                        width: parent.width
                        spacing: 8
                        Item { width: 48; height: 16 }
                        Repeater {
                            model: KanaCatalog.vowels
                            delegate: Text {
                                required property string modelData
                                width: (chart.width - 48 - 40) / 5
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.toUpperCase()
                                color: Theme.textMuted
                                font.family: Theme.fontBody
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 2
                            }
                        }
                    }

                    Repeater {
                        model: KanaCatalog.rows
                        delegate: Row {
                            id: kanaRow
                            required property var modelData
                            width: chart.width
                            spacing: 8

                            Column {
                                width: 48
                                height: 64
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: kanaRow.modelData.short
                                    color: Theme.text
                                    font.family: Theme.fontBody
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: kanaRow.modelData.group.toUpperCase()
                                    color: Theme.textMuted
                                    font.family: Theme.fontBody
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.2
                                }
                            }

                            Repeater {
                                model: 5
                                delegate: Item {
                                    id: slot
                                    required property int index
                                    readonly property string romaji: kanaRow.modelData.romaji[index]
                                    readonly property string glyph: (root.katakana ? kanaRow.modelData.kata : kanaRow.modelData.hira)[index]
                                    readonly property string status: romaji && root.mastery[romaji] ? root.mastery[romaji] : "new"
                                    width: (chart.width - 48 - 40) / 5
                                    height: 64

                                    KanaCell {
                                        anchors.fill: parent
                                        visible: slot.glyph !== ""
                                        kana: slot.glyph
                                        romaji: slot.romaji
                                        mastery: slot.status
                                        dimmed: root.filter !== "all" && root.filter !== slot.status
                                        onActivated: root.openDetail(slot.romaji)
                                        HoverHandler {
                                            id: slotHover
                                            onHoveredChanged: {
                                                if (slotHover.hovered && slot.romaji)
                                                    root.hovered = slot.romaji
                                            }
                                        }
                                    }
                                    Rectangle {
                                        visible: slot.glyph === ""
                                        width: 4
                                        height: 4
                                        radius: 2
                                        anchors.centerIn: parent
                                        color: Theme.line
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                Layout.preferredWidth: 280
                Layout.alignment: Qt.AlignTop
                spacing: 0

                Text {
                    text: "PREVIEW · 预览"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2.2
                }
                Item {
                    width: parent.width
                    height: 188
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.entry ? root.entry.char : ""
                        color: Theme.text
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.kanaHero
                        font.bold: true
                    }
                }
                Text {
                    text: root.entry ? root.entry.romaji.toUpperCase() : ""
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 4
                }

                Item {
                    width: 280
                    height: 96
                    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text { text: "平假名"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                        Text { text: root.entry ? root.entry.hira : ""; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 40; font.bold: true }
                    }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 56; color: Theme.border }
                    Column {
                        anchors.left: parent.horizontalCenter
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text { text: "片假名"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                        Text { text: root.entry ? root.entry.kata : ""; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 40; font.bold: true }
                    }
                }

                Text {
                    width: parent.width
                    topPadding: 16
                    wrapMode: Text.WordWrap
                    text: root.entry ? root.entry.mnemonic : ""
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    lineHeight: 1.45
                }

                Item { width: 1; height: 28 }
                Column {
                    width: parent.width
                    spacing: 8
                    Row {
                        width: parent.width
                        spacing: 8
                        Rectangle { width: 12; height: 12; radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "已掌握"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: parent.width - 120; height: 1 }
                        Text {
                            text: root.stats.mastered + "/" + root.stats.total
                            color: Theme.text
                            font.pixelSize: 12
                            font.family: Theme.fontBody
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 2
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.line
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 2; height: 2; color: Theme.accent }
                        }
                        Text { text: "正在学"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        spacing: 8
                        Rectangle { width: 12; height: 12; radius: 2; color: "transparent"; border.width: 1; border.color: Theme.line; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "未学"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }
}
