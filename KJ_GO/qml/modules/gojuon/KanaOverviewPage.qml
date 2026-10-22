import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property string language: "ja"
    property string layoutId: "ja-gojuon-seion"
    property bool katakana: false
    property string filter: "all"
    property string hovered: "ja:syllable:a"
    property string pickedInitial: ""
    property bool boardReady: false
    signal toggleScript(bool katakana)

    readonly property bool korean: language === "ko"
    readonly property int pageInset: 48
    readonly property int rowHeadW: korean ? 32 : 44
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
    readonly property var hangulRow: {
        var rows = root.board.rows || []
        for (var i = 0; i < rows.length; ++i) {
            if (rows[i].short === root.pickedInitial)
                return rows[i]
        }
        return rows.length > 0 ? rows[0] : null
    }
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

    function firstCell(row) {
        if (!row)
            return ""
        if (row.sections && row.sections.length > 0) {
            var grouped = row.sections[0].cells || []
            if (grouped.length > 0 && grouped[0].id)
                return grouped[0].id
        }
        var cells = row.cells || []
        return cells.length > 0 && cells[0].id ? cells[0].id : ""
    }

    function focusLayout() {
        var data = studyStore.layout(root.layoutId)
        var rows = data.rows || []
        hovered = rows.length > 0 ? firstCell(rows[0]) : ""
        pickedInitial = rows.length > 0 ? rows[0].short : ""
        if (chartScroll)
            chartScroll.contentY = 0
    }

    onLayoutIdChanged: {
        if (boardReady)
            focusLayout()
    }

    function chooseInitial(short) {
        pickedInitial = short
        var row = null
        var rows = board.rows || []
        for (var i = 0; i < rows.length; ++i) {
            if (rows[i].short === short) {
                row = rows[i]
                break
            }
        }
        var id = firstCell(row)
        if (id)
            hovered = id
        if (chartScroll)
            chartScroll.contentY = 0
    }

    function speak(audio) {
        if (audio)
            kanaPlayer.play(audio)
    }

    function statusText(status) {
        if (status === "mastered")
            return "已掌握"
        if (status === "fuzzy")
            return "模糊"
        return "未掌握"
    }

    function statusColor(status) {
        if (status === "mastered")
            return Theme.primary
        if (status === "fuzzy")
            return Theme.textMuted
        return Theme.accent
    }

    property string mnemonicItem: ""

    function loadMnemonic() {
        if (mnemonicItem && mnemonicItem !== root.hovered)
            studyStore.setMnemonic(mnemonicItem, mnemonicEdit.text)
        mnemonicItem = root.hovered
        var card = root.hovered ? studyStore.item(root.hovered) : ({})
        mnemonicEdit.text = card && card.mnemonic ? card.mnemonic : ""
    }

    onHoveredChanged: loadMnemonic()
    Component.onCompleted: {
        boardReady = true
        focusLayout()
        loadMnemonic()
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
                    text: root.board.title || (root.korean ? "한글" : "五十音図")
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.title
                    font.bold: true
                }
            }
            Row {
                Layout.alignment: Qt.AlignBottom
                spacing: 4

                component FilterChip: Rectangle {
                    id: chip
                    property string label: ""
                    property string key: "all"
                    property color ink: Theme.text
                    implicitWidth: chipLabel.implicitWidth + 20
                    implicitHeight: 32
                    radius: Theme.radiusSm
                    color: root.filter === key ? Theme.text : "transparent"
                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: chip.label
                        color: root.filter === chip.key ? Theme.bg : chip.ink
                        font.family: Theme.fontBody
                        font.pixelSize: 14
                        font.bold: root.filter === chip.key
                    }
                    TapHandler { onTapped: root.filter = chip.key }
                }

                FilterChip { label: "全部"; key: "all"; ink: Theme.text }
                FilterChip { label: "已掌握"; key: "mastered"; ink: Theme.primary }
                FilterChip { label: "模糊"; key: "fuzzy"; ink: Theme.textMuted }
                FilterChip { label: "未掌握"; key: "unlearned"; ink: Theme.accent }
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

        Flow {
            visible: root.korean
            Layout.fillWidth: true
            Layout.leftMargin: root.pageInset
            Layout.rightMargin: 48
            spacing: 8
            Repeater {
                model: root.board.rows
                delegate: Rectangle {
                    id: initialChip
                    required property var modelData
                    readonly property bool chosen: root.hangulRow && root.hangulRow.short === modelData.short
                    implicitWidth: initialText.implicitWidth + 18
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: chosen ? Theme.text : (initialHover.hovered ? Theme.muted : "transparent")
                    border.width: chosen ? 0 : 1
                    border.color: Theme.line
                    Text {
                        id: initialText
                        anchors.centerIn: parent
                        text: initialChip.modelData.short
                        color: initialChip.chosen ? Theme.bg : Theme.text
                        font.family: Theme.fontDisplay
                        font.pixelSize: 18
                        font.bold: true
                    }
                    HoverHandler { id: initialHover }
                    TapHandler { onTapped: root.chooseInitial(initialChip.modelData.short) }
                }
            }
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
                        visible: !root.korean
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
                        model: root.korean ? [] : root.board.rows
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
                                    readonly property string status: slot.modelData && slot.modelData.status ? slot.modelData.status : "unlearned"
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

                    Column {
                        width: parent.width
                        visible: root.korean
                        spacing: 22

                        Repeater {
                            model: root.hangulRow && root.hangulRow.sections ? root.hangulRow.sections : []
                            delegate: Column {
                                id: vowelGroup
                                required property var modelData
                                width: chart.width
                                spacing: 10
                                Text {
                                    text: vowelGroup.modelData.label
                                    color: Theme.text
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 10
                                    Repeater {
                                        model: vowelGroup.modelData.cells || []
                                        delegate: Item {
                                            id: hangulSlot
                                            required property var modelData
                                            readonly property string status: modelData && modelData.status ? modelData.status : "unlearned"
                                            width: 96
                                            height: 72
                                            visible: modelData && modelData.glyph
                                            KanaCell {
                                                anchors.fill: parent
                                                kana: hangulSlot.modelData.glyph
                                                romaji: hangulSlot.modelData.reading || ""
                                                mastery: hangulSlot.status
                                                dimmed: root.filter !== "all" && root.filter !== hangulSlot.status
                                                onActivated: root.speak(hangulSlot.modelData.audio || "")
                                                HoverHandler {
                                                    id: hangulHover
                                                    onHoveredChanged: {
                                                        if (hangulHover.hovered && hangulSlot.modelData.id)
                                                            root.hovered = hangulSlot.modelData.id
                                                    }
                                                }
                                            }
                                        }
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
                        font.pixelSize: root.heroGlyph.length > 1 ? 108 : Theme.kanaHero
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
                    font.letterSpacing: root.entry && root.entry.reading && root.entry.reading.length > 4 ? 1 : 4
                }

                Item {
                    id: pairBox
                    width: 280
                    height: 96
                    readonly property var pairs: {
                        var entry = root.entry || ({})
                        var list = []
                        if (entry.pairLeftLabel)
                            list.push({ label: entry.pairLeftLabel, glyph: entry.pairLeft || "" })
                        if (entry.pairRightLabel)
                            list.push({ label: entry.pairRightLabel, glyph: entry.pairRight || "" })
                        if (entry.pairCodaLabel)
                            list.push({ label: entry.pairCodaLabel, glyph: entry.pairCoda || "无" })
                        return list
                    }
                    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: pairBox.pairs
                            delegate: Item {
                                id: pairSlot
                                required property var modelData
                                required property int index
                                width: pairBox.width / Math.max(1, pairBox.pairs.length)
                                height: pairBox.height
                                Rectangle {
                                    visible: pairSlot.index > 0
                                    width: 1
                                    height: 56
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.border
                                }
                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: pairSlot.index === 0 ? 0 : 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    Text {
                                        text: pairSlot.modelData.label
                                        color: Theme.textMuted
                                        font.pixelSize: 10
                                        font.letterSpacing: 1.8
                                        font.family: Theme.fontBody
                                    }
                                    Text {
                                        text: pairSlot.modelData.glyph
                                        color: Theme.text
                                        font.family: Theme.fontDisplay
                                        font.pixelSize: pairBox.pairs.length > 2 ? 32 : 40
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: 28 }
                Column {
                    spacing: 6
                    Text { text: "状态"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.8; font.family: Theme.fontBody }
                    Text {
                        text: root.statusText(root.entry ? root.entry.status : "")
                        color: root.statusColor(root.entry ? root.entry.status : "")
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontBody
                    }
                }

                Item { width: 1; height: 22 }
                Text {
                    text: "联想"
                    color: Theme.textMuted
                    font.pixelSize: 10
                    font.letterSpacing: 1.8
                    font.family: Theme.fontBody
                }
                TextArea {
                    id: mnemonicEdit
                    width: parent.width
                    height: 120
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 0
                    rightPadding: 0
                    wrapMode: TextArea.Wrap
                    placeholderText: "写下你的联想"
                    color: Theme.text
                    placeholderTextColor: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    background: Rectangle { color: "transparent" }
                    onEditingFinished: studyStore.setMnemonic(root.hovered, text)
                }
            }
            }
        }
    }
}
