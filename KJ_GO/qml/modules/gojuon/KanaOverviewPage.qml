import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property string language: "ja"
    property bool katakana: false
    property string filter: "all"
    property string hovered: "ja:syllable:a"
    signal toggleScript(bool katakana)

    readonly property bool korean: language === "ko"
    readonly property string layoutId: korean ? "ko-syllable" : "ja-gojuon-seion"
    readonly property int pageInset: 48
    readonly property int rowHeadW: korean ? 32 : Theme.navInset - 8
    readonly property int chartShift: 20
    readonly property int scrollGap: 16
    readonly property var board: {
        var rev = studyStore.revision
        var data = studyStore.layout(root.layoutId)
        if (!data || !data.columns)
            return { columns: [], rows: [], eyebrow: "", title: "", columnSerif: false }
        return data
    }
    readonly property int chartCols: Math.max(1, root.board.columns.length)
    readonly property var entry: {
        var rev = studyStore.revision
        return root.hovered ? studyStore.item(root.hovered) : ({})
    }
    readonly property string heroGlyph: {
        if (!root.entry || !root.entry.glyph)
            return ""
        if (root.katakana && root.entry.glyphAlt)
            return root.entry.glyphAlt
        return root.entry.glyph
    }

    onLanguageChanged: {
        var data = studyStore.layout(root.layoutId)
        var first = data.rows && data.rows.length > 0 ? data.rows[0].cells[0].id : ""
        hovered = first
        chartScroll.contentY = 0
    }

    function speak(audio) {
        if (audio)
            kanaPlayer.play(audio)
    }

    function pad(value, width) {
        var text = "" + value
        while (text.length < width)
            text = "0" + text
        return text
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 48
        anchors.topMargin: 40
        anchors.bottomMargin: 32
        spacing: 28

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.pageInset
            spacing: 20
            ColumnLayout {
                spacing: 8
                Text {
                    text: root.board.eyebrow || ""
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2.4
                }
                Text {
                    text: root.board.title || ""
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.title
                    font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            ScriptToggle {
                visible: !root.korean
                katakana: root.katakana
                onChanged: root.toggleScript(katakana)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: root.pageInset
            height: 1
            color: Theme.border
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 0
                spacing: 28

                Flickable {
                id: chartScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: root.chartShift
                contentWidth: width
                contentHeight: chart.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    parent: chartScroll.parent
                    anchors.top: chartScroll.top
                    anchors.bottom: chartScroll.bottom
                    anchors.left: chartScroll.right
                    anchors.leftMargin: 0
                }

                Column {
                    id: chart
                    width: Math.max(0, chartScroll.width - root.scrollGap)
                    spacing: 8

                    Row {
                        width: parent.width
                        spacing: 8
                        Item { width: root.rowHeadW; height: 16 }
                        Repeater {
                            model: root.board.columns
                            delegate: Text {
                                required property string modelData
                                width: (chart.width - root.rowHeadW - root.chartCols * 8) / root.chartCols
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: Theme.textMuted
                                font.family: root.board.columnSerif ? Theme.fontDisplay : Theme.fontBody
                                font.pixelSize: root.board.columnSerif ? 16 : 10
                                font.bold: true
                                font.letterSpacing: root.board.columnSerif ? 0 : 2
                            }
                        }
                    }

                    Repeater {
                        model: root.board.rows
                        delegate: Row {
                            id: kanaRow
                            required property var modelData
                            width: chart.width
                            spacing: 8

                            Column {
                                width: root.rowHeadW
                                height: 64
                                spacing: 2
                                Text {
                                    anchors.left: parent.left
                                    text: kanaRow.modelData.short
                                    color: Theme.text
                                    font.family: Theme.fontBody
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    anchors.left: parent.left
                                    text: kanaRow.modelData.group.toUpperCase()
                                    color: Theme.textMuted
                                    font.family: Theme.fontBody
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.2
                                }
                            }

                            Repeater {
                                model: kanaRow.modelData.cells
                                delegate: Item {
                                    id: slot
                                    required property var modelData
                                    readonly property string glyph: {
                                        if (!slot.modelData || !slot.modelData.id)
                                            return ""
                                        if (root.katakana && slot.modelData.glyphAlt)
                                            return slot.modelData.glyphAlt
                                        return slot.modelData.glyph
                                    }
                                    readonly property string status: slot.modelData && slot.modelData.status ? slot.modelData.status : "new"
                                    width: (chart.width - root.rowHeadW - root.chartCols * 8) / root.chartCols
                                    height: 64

                                    KanaCell {
                                        anchors.fill: parent
                                        visible: slot.glyph !== ""
                                        kana: slot.glyph
                                        romaji: slot.modelData.reading || ""
                                        mastery: slot.status
                                        dimmed: root.filter !== "all" && root.filter !== slot.status
                                        onActivated: root.speak(slot.modelData.audio || "")
                                        HoverHandler {
                                            id: slotHover
                                            onHoveredChanged: {
                                                if (slotHover.hovered && slot.modelData.id)
                                                    root.hovered = slot.modelData.id
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

                Item {
                    width: parent.width
                    height: 188
                    Text {
                        id: hero
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.heroGlyph
                        color: Theme.text
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.kanaHero
                        font.bold: true
                    }
                    Item {
                        id: speakerBtn
                        width: 36
                        height: 36
                        anchors.left: hero.right
                        anchors.bottom: hero.bottom
                        visible: root.entry && root.entry.audio !== ""
                        anchors.leftMargin: 2
                        anchors.bottomMargin: 22
                        readonly property bool playing: kanaPlayer.playing
                        property int wave: 3
                        property color ink: playing ? Theme.text : (speakerHover.hovered ? Theme.text : Theme.textMuted)

                        Timer {
                            interval: 160
                            repeat: true
                            running: speakerBtn.playing
                            onTriggered: speakerBtn.wave = speakerBtn.wave % 3 + 1
                        }
                        onPlayingChanged: {
                            if (!speakerBtn.playing)
                                speakerBtn.wave = 3
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 18
                            color: speakerHover.hovered ? Theme.muted : "transparent"
                        }
                        Canvas {
                            id: hornCanvas
                            width: 22
                            height: 16
                            anchors.centerIn: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.globalAlpha = 1
                                ctx.fillStyle = speakerBtn.ink
                                ctx.beginPath()
                                ctx.moveTo(1, 5)
                                ctx.lineTo(5, 5)
                                ctx.lineTo(10, 1)
                                ctx.lineTo(10, 15)
                                ctx.lineTo(5, 11)
                                ctx.lineTo(1, 11)
                                ctx.closePath()
                                ctx.fill()
                                ctx.strokeStyle = speakerBtn.ink
                                ctx.lineWidth = 1.5
                                ctx.lineCap = "round"
                                for (var i = 0; i < 3; ++i) {
                                    ctx.globalAlpha = speakerBtn.playing ? (i < speakerBtn.wave ? 1 : 0.18) : 0.45
                                    ctx.beginPath()
                                    ctx.arc(11, 8, 3.2 + i * 3.1, -0.9, 0.9)
                                    ctx.stroke()
                                }
                            }
                        }
                        onInkChanged: hornCanvas.requestPaint()
                        onWaveChanged: hornCanvas.requestPaint()
                        HoverHandler { id: speakerHover }
                        TapHandler { onTapped: root.speak(root.entry ? root.entry.audio : "") }
                    }
                }
                Text {
                    text: root.entry && root.entry.reading ? root.entry.reading.toUpperCase() : ""
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
                        Text { text: root.entry && root.entry.pairLeftLabel ? root.entry.pairLeftLabel : ""; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                        Text { text: root.entry && root.entry.pairLeft ? root.entry.pairLeft : ""; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 40; font.bold: true }
                    }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 56; color: Theme.border }
                    Column {
                        anchors.left: parent.horizontalCenter
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text { text: root.entry && root.entry.pairRightLabel ? root.entry.pairRightLabel : ""; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                        Text { text: root.entry && root.entry.pairRight ? root.entry.pairRight : ""; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 40; font.bold: true }
                    }
                }

                Text {
                    visible: root.entry && root.entry.mnemonic !== ""
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
                    spacing: 18

                    Row {
                        width: parent.width
                        spacing: 28
                        Column {
                            spacing: 6
                            Text { text: "位置"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                            Text {
                                text: root.entry && root.entry.rowLabel ? root.entry.rowLabel + " · " + root.entry.columnLabel : ""
                                color: Theme.text
                                font.pixelSize: 16
                                font.family: Theme.fontBody
                            }
                        }
                        Column {
                            spacing: 6
                            Text { text: "顺序"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                            Text {
                                text: root.entry && root.entry.position
                                      ? root.pad(root.entry.position, root.korean ? 3 : 2) + "  /  " + root.entry.total
                                      : ""
                                color: Theme.text
                                font.pixelSize: 16
                                font.family: Theme.fontBody
                            }
                        }
                    }

                    Column {
                        visible: root.entry && root.entry.lookalikes && root.entry.lookalikes.length > 0
                        spacing: 8
                        Text { text: "易混"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                        Row {
                            spacing: 16
                            Repeater {
                                model: root.entry && root.entry.lookalikes ? root.entry.lookalikes : []
                                delegate: Text {
                                    required property var modelData
                                    text: root.katakana && modelData.glyphAlt ? modelData.glyphAlt : modelData.glyph
                                    color: Theme.text
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: 32
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.entry && root.entry.weak
                        spacing: 6
                        Text { text: "弱项"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                        Text { text: "在复习队列里"; color: Theme.accent; font.pixelSize: 16; font.family: Theme.fontBody }
                    }
                }
            }
            }
        }
    }
}
