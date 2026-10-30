import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property string setId: "ja-seion"
    property string queueMode: "today"
    property string frontScript: "hira"
    signal exit()

    property var queue: []
    property int index: 0
    property bool flipped: false
    property int correctCount: 0
    property int wrongCount: 0
    property bool cardsReady: false
    property bool vocabDeck: false
    property var frontPick: ({})

    readonly property bool finished: queue.length === 0 || index >= queue.length
    readonly property string currentId: queue.length === 0 ? "" : queue[Math.min(index, queue.length - 1)]
    readonly property var entry: {
        var rev = studyStore.revision
        return root.currentId ? studyStore.item(root.currentId) : null
    }

    function showFront() {
        if (!cardsReady)
            return
        flipBehavior.enabled = false
        flipped = false
        flipBehavior.enabled = true
    }

    function shuffle(ids) {
        var list = []
        for (var i = 0; i < ids.length; ++i)
            list.push(ids[i])
        for (var j = list.length - 1; j > 0; --j) {
            var k = Math.floor(Math.random() * (j + 1))
            var tmp = list[j]
            list[j] = list[k]
            list[k] = tmp
        }
        return list
    }

    function loadQueue() {
        if (queueMode === "fuzzy")
            return studyStore.weakIds(setId)
        if (queueMode === "all")
            return shuffle(studyStore.itemIds(setId))
        return studyStore.reviewQueue(setId, 12)
    }

    function buildFrontPick(ids) {
        var pick = {}
        for (var i = 0; i < ids.length; ++i) {
            var card = studyStore.item(ids[i])
            if (card && card.kind === "vocab")
                pick[ids[i]] = Math.random() < 0.5 ? "gloss" : "word"
            else
                pick[ids[i]] = (card && card.glyphAlt && Math.random() < 0.5) ? "kata" : "hira"
        }
        frontPick = pick
    }

    function showingGloss(entry) {
        if (!entry || entry.kind !== "vocab")
            return false
        if (frontScript === "gloss")
            return true
        if (frontScript === "mix")
            return frontPick[entry.id] === "gloss"
        return false
    }

    function showingKata(entry) {
        if (!entry || !entry.glyphAlt)
            return false
        if (frontScript === "kata")
            return true
        if (frontScript === "mix")
            return frontPick[entry.id] === "kata"
        return false
    }

    function frontGlyph(entry) {
        if (!entry)
            return ""
        if (entry.kind === "vocab")
            return showingGloss(entry) ? entry.gloss : entry.glyph
        return showingKata(entry) ? entry.glyphAlt : entry.glyph
    }

    function frontCaption(entry) {
        if (!entry)
            return "FRONT"
        if (entry.kind === "vocab") {
            if (showingGloss(entry))
                return "释义 · FRONT"
            return PosCatalog.textOf(entry.pos) + " · FRONT"
        }
        var label = showingKata(entry) ? entry.pairRightLabel : entry.pairLeftLabel
        return (label ? label : "") + " · FRONT"
    }

    function frontHint(entry) {
        if (entry && entry.kind === "vocab")
            return showingGloss(entry) ? "韩语怎么说？" : "意思和用法是？"
        return "它读作什么？"
    }

    function heroSize(text) {
        var n = text ? text.length : 1
        if (!vocabDeck)
            return n <= 1 ? Theme.kanaHero : 108
        if (n <= 2)
            return 108
        if (n <= 4)
            return 72
        if (n <= 6)
            return 48
        if (n <= 10)
            return 36
        return 28
    }

    function vocabAnswer(entry) {
        if (!entry)
            return ""
        return showingGloss(entry) ? entry.glyph : entry.gloss
    }

    function promptKind() {
        if (!entry || entry.kind !== "vocab")
            return "glyph-to-reading"
        return showingGloss(entry) ? "gloss-to-word" : "word-to-gloss"
    }

    function queueTitle() {
        if (queueMode === "fuzzy")
            return "模糊 · FUZZY"
        if (queueMode === "all")
            return "全部 · ALL"
        return "今日复习 · REVIEW"
    }

    function reload() {
        var ids = loadQueue()
        var first = ids.length > 0 ? studyStore.item(ids[0]) : null
        vocabDeck = first ? first.kind === "vocab" : setId.indexOf("vocab") !== -1
        buildFrontPick(ids)
        queue = ids
        index = 0
        correctCount = 0
        wrongCount = 0
        if (cardsReady)
            showFront()
        else
            flipped = false
    }

    function choose(correct) {
        if (!flipped || finished || !currentId)
            return
        studyStore.rate(currentId, correct, "flashcard", promptKind())
        if (correct)
            correctCount += 1
        else
            wrongCount += 1
        showFront()
        index += 1
    }

    onSetIdChanged: reload()
    onQueueModeChanged: reload()
    onFrontScriptChanged: {
        if (frontScript === "mix")
            buildFrontPick(queue)
    }
    Component.onCompleted: {
        cardsReady = true
        reload()
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.queueTitle()
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.2
            }
            Text {
                text: (Math.min(root.index + 1, Math.max(root.queue.length, 1)) < 10 ? "0" : "") + Math.min(root.index + 1, Math.max(root.queue.length, 1))
                color: Theme.text
                font.family: Theme.fontBody
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                text: " / " + root.queue.length
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 14
            }
            Item { Layout.fillWidth: true }
            Row {
                spacing: 8
                Text { text: "退出"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Kbd { text: "Esc"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "×"; color: Theme.textMuted; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                TapHandler { onTapped: root.exit() }
            }
        }

        Row {
            Layout.fillWidth: true
            height: 2
            spacing: 4
            Repeater {
                model: root.queue.length
                delegate: Rectangle {
                    required property int index
                    width: root.queue.length > 0 ? (parent.width - (root.queue.length - 1) * 4) / root.queue.length : 0
                    height: 2
                    color: index < root.index ? Theme.accent : Theme.border
                }
            }
        }

        Item { Layout.fillHeight: true }

        Column {
            visible: root.finished
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "終"
                color: Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: 128
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SESSION COMPLETE"
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 12
                font.letterSpacing: 3
            }
            Item { width: 1; height: 24 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 48
                Column {
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.wrongCount; font.pixelSize: 28; font.bold: true; color: Theme.text; font.family: Theme.fontBody }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "错了"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody }
                }
                Column {
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.correctCount; font.pixelSize: 28; font.bold: true; color: Theme.text; font.family: Theme.fontBody }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "对了"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: restartRow.implicitWidth + 40
                height: 44
                radius: Theme.radiusMd
                color: "transparent"
                border.width: 1
                border.color: restartHover.hovered ? Theme.text : Theme.line
                Row {
                    id: restartRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "再来一轮"; color: Theme.text; font.family: Theme.fontBody; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Kbd { text: "Enter"; anchors.verticalCenter: parent.verticalCenter }
                }
                HoverHandler { id: restartHover }
                TapHandler { onTapped: root.reload() }
            }
        }

        Column {
            visible: !root.finished
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28

            Item {
                id: scene
                width: root.vocabDeck ? 480 : 400
                height: root.vocabDeck ? 520 : 440
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    id: inner
                    anchors.fill: parent
                    transform: Rotation {
                        id: spin
                        origin: Qt.vector3d(inner.width / 2, inner.height / 2, 0)
                        axis: Qt.vector3d(0, 1, 0)
                        angle: root.flipped ? 180 : 0
                        Behavior on angle {
                            id: flipBehavior
                            NumberAnimation { duration: Theme.durFlip; easing.type: Easing.InOutCubic }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: spin.angle < 90 || spin.angle > 270
                        radius: 12
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border
                        MouseArea { anchors.fill: parent; onClicked: root.flipped = true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 28; text: root.frontCaption(root.entry); color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 2.2; font.family: Theme.fontBody }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 72
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.frontGlyph(root.entry)
                            color: Theme.text
                            font.family: root.vocabDeck && root.showingGloss(root.entry) ? Theme.fontBody : Theme.fontDisplay
                            font.pixelSize: root.heroSize(text)
                            font.bold: true
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; text: root.frontHint(root.entry); color: Theme.textMuted; font.pixelSize: 11; font.letterSpacing: 1.4; font.family: Theme.fontBody }
                    }

                    Rectangle {
                        id: backFace
                        anchors.fill: parent
                        visible: spin.angle >= 90 && spin.angle <= 270
                        radius: 12
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border
                        transform: Rotation {
                            origin: Qt.vector3d(backFace.width / 2, backFace.height / 2, 0)
                            axis: Qt.vector3d(0, 1, 0)
                            angle: 180
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.flipped = false }
                        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 2; color: Theme.primary }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 28; text: "答案 · BACK"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 2.2; font.family: Theme.fontBody }
                        Column {
                            visible: !root.vocabDeck
                            anchors.centerIn: parent
                            spacing: 20
                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: readingText.implicitWidth + (cardSpeaker.visible ? 46 : 0)
                                height: readingText.implicitHeight
                                Text {
                                    id: readingText
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.entry && root.entry.reading ? root.entry.reading.toUpperCase() : ""
                                    color: Theme.text
                                    font.family: Theme.fontBody
                                    font.pixelSize: 48
                                    font.letterSpacing: root.entry && root.entry.reading && root.entry.reading.length > 3 ? 2 : 8
                                }
                                Item {
                                    id: cardSpeaker
                                    width: 36
                                    height: 36
                                    anchors.left: readingText.right
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.entry && root.entry.audio !== ""
                                    readonly property bool playing: kanaPlayer.playing
                                    property int wave: 3
                                    property color ink: playing ? Theme.text : (cardSpeakerHover.hovered ? Theme.text : Theme.textMuted)

                                    Timer {
                                        interval: 160
                                        repeat: true
                                        running: cardSpeaker.playing
                                        onTriggered: cardSpeaker.wave = cardSpeaker.wave % 3 + 1
                                    }
                                    onPlayingChanged: {
                                        if (!cardSpeaker.playing)
                                            cardSpeaker.wave = 3
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 18
                                        color: cardSpeakerHover.hovered ? Theme.muted : "transparent"
                                    }
                                    Canvas {
                                        id: cardHorn
                                        width: 22
                                        height: 16
                                        anchors.centerIn: parent
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            ctx.globalAlpha = 1
                                            ctx.fillStyle = cardSpeaker.ink
                                            ctx.beginPath()
                                            ctx.moveTo(1, 5)
                                            ctx.lineTo(5, 5)
                                            ctx.lineTo(10, 1)
                                            ctx.lineTo(10, 15)
                                            ctx.lineTo(5, 11)
                                            ctx.lineTo(1, 11)
                                            ctx.closePath()
                                            ctx.fill()
                                            ctx.strokeStyle = cardSpeaker.ink
                                            ctx.lineWidth = 1.5
                                            ctx.lineCap = "round"
                                            for (var i = 0; i < 3; ++i) {
                                                ctx.globalAlpha = cardSpeaker.playing ? (i < cardSpeaker.wave ? 1 : 0.18) : 0.45
                                                ctx.beginPath()
                                                ctx.arc(11, 8, 3.2 + i * 3.1, -0.9, 0.9)
                                                ctx.stroke()
                                            }
                                        }
                                    }
                                    onInkChanged: cardHorn.requestPaint()
                                    onWaveChanged: cardHorn.requestPaint()
                                    HoverHandler { id: cardSpeakerHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.entry && root.entry.audio)
                                                kanaPlayer.play(root.entry.audio)
                                        }
                                    }
                                }
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 28
                                Column {
                                    spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.entry ? root.entry.pairLeft : ""; font.family: Theme.fontDisplay; font.pixelSize: 56; font.bold: true; color: Theme.text }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.entry ? root.entry.pairLeftLabel : ""; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.6; font.family: Theme.fontBody }
                                }
                                Rectangle { width: 1; height: 64; color: Theme.line }
                                Column {
                                    spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.entry ? root.entry.pairRight : ""; font.family: Theme.fontDisplay; font.pixelSize: 56; font.bold: true; color: Theme.primary }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.entry ? root.entry.pairRightLabel : ""; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.6; font.family: Theme.fontBody }
                                }
                            }
                        }
                        Column {
                            visible: root.vocabDeck
                            width: parent.width - 64
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 8
                            spacing: 18
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: !root.entry ? "" : PosCatalog.textOf(root.entry.pos)
                                color: Theme.textMuted
                                font.family: Theme.fontBody
                                font.pixelSize: 11
                                font.letterSpacing: 1.6
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root.vocabAnswer(root.entry)
                                color: Theme.text
                                font.family: root.showingGloss(root.entry) ? Theme.fontDisplay : Theme.fontBody
                                font.pixelSize: root.heroSize(text)
                                font.bold: true
                            }
                            Text {
                                width: parent.width
                                visible: root.entry && root.entry.example
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root.entry ? root.entry.example : ""
                                color: Theme.text
                                font.family: Theme.fontBody
                                font.pixelSize: 16
                            }
                            Text {
                                width: parent.width
                                visible: root.entry && root.entry.mnemonic
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root.entry ? root.entry.mnemonic : ""
                                color: Theme.textMuted
                                font.family: Theme.fontBody
                                font.pixelSize: 15
                            }
                        }
                        Text {
                            visible: !root.vocabDeck
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 24
                            width: parent.width - 48
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.entry ? root.entry.mnemonic : ""
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 12
                        }
                    }

                }
            }

            Item {
                width: 400
                height: 64
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    visible: !root.flipped
                    anchors.centerIn: parent
                    text: "点击卡片翻面"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Row {
                    visible: root.flipped
                    anchors.centerIn: parent
                    spacing: 12
                    Rectangle {
                        width: 160
                        height: 64
                        radius: Theme.radiusMd
                        color: wrongHover.hovered ? Theme.accent : "transparent"
                        border.width: 1
                        border.color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: "错了"
                            color: wrongHover.hovered ? Theme.primaryFg : Theme.accent
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontBody
                        }
                        HoverHandler { id: wrongHover }
                        TapHandler { onTapped: root.choose(false) }
                    }
                    Rectangle {
                        width: 160
                        height: 64
                        radius: Theme.radiusMd
                        color: Theme.primary
                        Text {
                            anchors.centerIn: parent
                            text: "对了"
                            color: Theme.primaryFg
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontBody
                        }
                        TapHandler { onTapped: root.choose(true) }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
