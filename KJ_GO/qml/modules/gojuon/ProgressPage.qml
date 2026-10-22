import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    property string language: "ja"
    property string view: "overview"
    property string heatSet: language === "ko" ? "ko-syllable" : "ja-seion"
    property string heatRow: ""
    property bool katakana: false

    readonly property var stats: {
        var rev = studyStore.revision
        return studyStore.progress(root.language) || {}
    }
    readonly property var sets: stats.sets || []
    readonly property var curve: stats.curve || []
    readonly property var misses: stats.misses || []
    readonly property int curveMax: {
        var maxValue = 1
        for (var i = 0; i < curve.length; ++i)
            maxValue = Math.max(maxValue, curve[i].reviews || 0)
        return maxValue
    }
    readonly property int fortnightReviews: {
        var total = 0
        for (var i = 0; i < curve.length; ++i)
            total += curve[i].reviews || 0
        return total
    }
    readonly property bool vocabHeat: heatSet.indexOf("vocab") !== -1
    readonly property bool rowHeat: heatSet === "ko-syllable"
    readonly property var heatBoard: {
        var rev = studyStore.revision
        var id = layoutFor(heatSet)
        if (!id)
            return null
        var data = studyStore.layout(id)
        return data && data.rows ? data : null
    }
    readonly property var heatRows: heatBoard && heatBoard.rows ? heatBoard.rows : []
    readonly property var heatRowData: {
        if (heatRows.length === 0)
            return null
        var want = heatRow || heatRows[0].short
        for (var i = 0; i < heatRows.length; ++i) {
            if (heatRows[i].short === want)
                return heatRows[i]
        }
        return heatRows[0]
    }
    readonly property var vocabList: {
        var rev = studyStore.revision
        if (!vocabHeat)
            return []
        return studyStore.items(heatSet) || []
    }
    readonly property string viewTitle: {
        if (view === "curve")
            return "记忆曲线"
        if (view === "heat")
            return "弱项热力图"
        return "总览"
    }
    readonly property int heatCols: Math.max(1, heatBoard && heatBoard.columns ? heatBoard.columns.length : 1)
    readonly property int rowHeadW: 44

    function layoutFor(setId) {
        if (setId === "ja-seion")
            return "ja-gojuon-seion"
        if (setId === "ja-dakuon")
            return "ja-gojuon-dakuon"
        if (setId === "ja-handakuon")
            return "ja-gojuon-handakuon"
        if (setId === "ja-youon")
            return "ja-gojuon-youon"
        if (setId === "ko-syllable")
            return "ko-syllable"
        return ""
    }

    function rateText(part, whole) {
        if (!whole)
            return "—"
        return Math.round(part / whole * 100) + "%"
    }

    function statusName(status) {
        if (status === "mastered")
            return "已掌握"
        if (status === "fuzzy")
            return "模糊"
        return "未掌握"
    }

    function cellGlyph(cell) {
        if (!cell)
            return ""
        if (katakana && cell.glyphAlt)
            return cell.glyphAlt
        return cell.glyph || ""
    }

    function barColor(day) {
        var reviews = day && day.reviews ? day.reviews : 0
        if (!reviews)
            return Theme.line
        var rate = day.right / reviews
        if (rate >= 0.8)
            return Theme.primary
        if (rate >= 0.5)
            return Theme.textMuted
        return Theme.accent
    }

    function weakShare(row) {
        var cells = row && row.cells ? row.cells : []
        var count = 0
        var weak = 0
        for (var i = 0; i < cells.length; ++i) {
            if (!cells[i] || !cells[i].id)
                continue
            count += 1
            if (cells[i].status !== "mastered")
                weak += 1
        }
        return count > 0 ? weak / count : 0
    }

    onLanguageChanged: {
        heatSet = language === "ko" ? "ko-syllable" : "ja-seion"
        heatRow = ""
        katakana = false
    }
    onHeatSetChanged: heatRow = ""
    onViewChanged: if (scroller) scroller.contentY = 0

    component StatTile: Rectangle {
        property string label: ""
        property string value: ""
        radius: Theme.radiusMd
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
                text: label
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
            }
            Text {
                text: value
                color: Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: 28
                font.bold: true
            }
        }
    }

    component HeatMark: Rectangle {
        id: mark
        property string glyph: ""
        property string reading: ""
        property string status: "unlearned"
        property string gloss: ""
        signal hovered()
        width: 56
        height: 52
        radius: Theme.radiusSm
        color: status === "mastered" ? Theme.primary : (status === "fuzzy" ? Theme.muted : "transparent")
        border.width: status === "mastered" ? 0 : 1
        border.color: status === "fuzzy" ? Theme.accent : Theme.line
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: gloss !== "" ? -7 : 0
            text: glyph
            color: status === "mastered" ? Theme.primaryFg : Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: glyph.length > 2 ? 14 : 20
            font.bold: true
        }
        Text {
            visible: gloss !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: parent.width - 6
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: gloss
            color: status === "mastered" ? Qt.rgba(Theme.primaryFg.r, Theme.primaryFg.g, Theme.primaryFg.b, 0.75) : Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 9
        }
        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    mark.hovered()
            }
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    Flickable {
        id: scroller
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 40
        anchors.topMargin: 28
        anchors.bottomMargin: 20
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: column
            width: scroller.width
            spacing: 28

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: "进度"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                }
                Text {
                    text: root.viewTitle
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.title
                    font.bold: true
                }
            }

            Column {
                width: parent.width
                spacing: 22
                visible: root.view === "overview"
                height: visible ? implicitHeight : 0

                Row {
                    width: parent.width
                    spacing: 12
                    StatTile {
                        width: (parent.width - 36) / 4
                        height: 88
                        label: "连续天数"
                        value: "" + (root.stats.streak || 0)
                    }
                    StatTile {
                        width: (parent.width - 36) / 4
                        height: 88
                        label: "今日复习"
                        value: "" + (root.stats.today || 0)
                    }
                    StatTile {
                        width: (parent.width - 36) / 4
                        height: 88
                        label: "正确率"
                        value: root.rateText(root.stats.right || 0, root.stats.reviews || 0)
                    }
                    StatTile {
                        width: (parent.width - 36) / 4
                        height: 88
                        label: "记忆保持"
                        value: root.rateText(root.stats.held || 0, root.stats.reviewed || 0)
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: root.sets
                        delegate: Rectangle {
                            id: setCard
                            required property var modelData
                            width: parent.width
                            height: 78
                            radius: Theme.radiusMd
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.border
                            readonly property int total: modelData.total || 0
                            readonly property int mastered: modelData.mastered || 0
                            readonly property int fuzzy: modelData.fuzzy || 0

                            Text {
                                id: setName
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.leftMargin: 16
                                anchors.topMargin: 14
                                text: modelData.label
                                color: Theme.text
                                font.family: Theme.fontBody
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: setName.verticalCenter
                                text: mastered + " / " + total
                                color: Theme.textMuted
                                font.family: Theme.fontBody
                                font.pixelSize: 13
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 16
                                height: 8
                                radius: 4
                                color: Theme.muted
                                clip: true
                                Row {
                                    width: parent.width
                                    height: parent.height
                                    visible: setCard.total > 0
                                    Rectangle {
                                        width: parent.width * setCard.mastered / setCard.total
                                        height: parent.height
                                        color: Theme.primary
                                    }
                                    Rectangle {
                                        width: parent.width * setCard.fuzzy / setCard.total
                                        height: parent.height
                                        color: Theme.accent
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    Text {
                        text: "最近打错"
                        color: Theme.text
                        font.family: Theme.fontBody
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        visible: root.misses.length === 0
                        text: (root.stats.reviews || 0) > 0 ? "最近一次都答对了。" : "还没有复习记录。做一轮闪卡之后，这里会记下打错的字。"
                        color: Theme.textMuted
                        font.family: Theme.fontBody
                        font.pixelSize: 14
                    }
                    Flow {
                        width: parent.width
                        spacing: 8
                        visible: root.misses.length > 0
                        Repeater {
                            model: root.misses
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.max(120, missBody.implicitWidth + 28)
                                height: 64
                                radius: Theme.radiusMd
                                color: Theme.surface
                                border.width: 1
                                border.color: Theme.border
                                Row {
                                    id: missBody
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    spacing: 10
                                    Text {
                                        text: modelData.glyph || ""
                                        color: Theme.text
                                        font.family: Theme.fontDisplay
                                        font.pixelSize: (modelData.glyph || "").length > 2 ? 18 : 26
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text {
                                            text: modelData.reading ? modelData.reading.toUpperCase() : (modelData.gloss || "")
                                            color: Theme.text
                                            font.family: Theme.fontBody
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Text {
                                            text: modelData.setLabel || ""
                                            color: Theme.textMuted
                                            font.family: Theme.fontBody
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 18
                visible: root.view === "curve"
                height: visible ? implicitHeight : 0

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.fortnightReviews > 0
                          ? ("近 14 天复习 " + root.fortnightReviews + " 次。柱子越高，当天练得越多；深蓝是当天正确率达到八成，红色是不足五成。记忆保持看全部练过的字里最近一次有没有答对，现在是 "
                             + root.rateText(root.stats.held || 0, root.stats.reviewed || 0) + "。")
                          : ((root.stats.reviews || 0) > 0
                             ? ("近 14 天没有新的复习。记忆保持仍按全部练过的字计算，现在是 "
                                + root.rateText(root.stats.held || 0, root.stats.reviewed || 0) + "。")
                             : "近 14 天还没有复习。闪卡里答过的题会出现在这里。")
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    lineHeight: 1.45
                }

                Item {
                    width: parent.width
                    height: 210
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: root.curve
                            delegate: Item {
                                required property var modelData
                                width: root.curve.length > 0 ? parent.width / root.curve.length : 0
                                height: parent.height
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: dayLabel.top
                                    anchors.bottomMargin: 8
                                    width: Math.min(26, Math.max(8, parent.width - 10))
                                    height: Math.max(modelData.reviews > 0 ? 6 : 2, 150 * (modelData.reviews || 0) / root.curveMax)
                                    radius: 3
                                    color: root.barColor(modelData)
                                }
                                Text {
                                    id: dayLabel
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: Theme.textMuted
                                    font.family: Theme.fontBody
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: root.view === "heat"
                height: visible ? implicitHeight : 0

                Row {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: root.sets
                        delegate: Rectangle {
                            id: setChip
                            required property var modelData
                            readonly property bool chosen: root.heatSet === modelData.id
                            implicitWidth: chipText.implicitWidth + 22
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: chosen ? Theme.text : "transparent"
                            border.width: chosen ? 0 : 1
                            border.color: Theme.line
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: setChip.chosen ? Theme.bg : Theme.text
                                font.family: Theme.fontBody
                                font.pixelSize: 14
                                font.bold: setChip.chosen
                            }
                            TapHandler { onTapped: root.heatSet = modelData.id }
                        }
                    }
                    Item { width: 12; height: 1 }
                    Rectangle {
                        visible: !root.vocabHeat && !root.rowHeat
                        implicitWidth: scriptText.implicitWidth + 20
                        implicitHeight: 32
                        radius: Theme.radiusSm
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.line
                        Text {
                            id: scriptText
                            anchors.centerIn: parent
                            text: root.katakana ? "片假名" : "平假名"
                            color: Theme.text
                            font.family: Theme.fontBody
                            font.pixelSize: 14
                        }
                        TapHandler { onTapped: root.katakana = !root.katakana }
                    }
                }

                Row {
                    spacing: 16
                    Rectangle { width: 14; height: 14; radius: 3; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "已掌握"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { width: 14; height: 14; radius: 3; color: Theme.muted; border.width: 1; border.color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "模糊"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { width: 14; height: 14; radius: 3; color: "transparent"; border.width: 1; border.color: Theme.line; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "未掌握"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }

                Text {
                    width: parent.width
                    text: root.heatNote
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }

                Flow {
                    width: parent.width
                    spacing: 8
                    visible: root.rowHeat && root.heatRows.length > 0
                    Repeater {
                        model: root.heatRows
                        delegate: Rectangle {
                            id: initialChip
                            required property var modelData
                            required property int index
                            readonly property bool chosen: root.heatRowData && root.heatRowData.short === modelData.short
                            readonly property real share: root.weakShare(modelData)
                            width: 36
                            height: 36
                            radius: Theme.radiusSm
                            color: chosen ? Theme.text : (share === 0 && (modelData.cells || []).length > 0 ? Theme.primary : (share > 0.66 ? Theme.accent : Theme.muted))
                            Text {
                                anchors.centerIn: parent
                                text: modelData.short
                                color: initialChip.chosen ? Theme.bg : (initialChip.share === 0 || initialChip.share > 0.66 ? Theme.primaryFg : Theme.text)
                                font.family: Theme.fontDisplay
                                font.pixelSize: 16
                                font.bold: true
                            }
                            TapHandler { onTapped: root.heatRow = modelData.short }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 14
                    visible: root.rowHeat && root.heatRowData
                    Repeater {
                        model: root.heatRowData && root.heatRowData.sections ? root.heatRowData.sections : []
                        delegate: Column {
                            id: sectionCol
                            required property var modelData
                            width: parent.width
                            spacing: 8
                            Text {
                                text: modelData.label
                                color: Theme.textMuted
                                font.family: Theme.fontDisplay
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Flow {
                                width: parent.width
                                spacing: 6
                                Repeater {
                                    model: sectionCol.modelData.cells || []
                                    delegate: HeatMark {
                                        required property var modelData
                                        visible: modelData.id !== ""
                                        width: 40
                                        height: 40
                                        glyph: root.cellGlyph(modelData)
                                        status: modelData.status || "unlearned"
                                        onHovered: root.heatNote = glyph + "  " + (modelData.reading || "").toUpperCase() + "  ·  " + root.statusName(status)
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: !root.vocabHeat && !root.rowHeat && root.heatBoard
                    Row {
                        width: parent.width
                        spacing: 8
                        Item { width: root.rowHeadW; height: 16 }
                        Repeater {
                            model: root.heatBoard ? root.heatBoard.columns : []
                            delegate: Text {
                                required property string modelData
                                width: Math.min(88, Math.max(36, (column.width - root.rowHeadW - root.heatCols * 8) / root.heatCols))
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: Theme.textMuted
                                font.family: root.heatBoard.columnSerif ? Theme.fontDisplay : Theme.fontBody
                                font.pixelSize: root.heatBoard.columnSerif ? 16 : 10
                                font.bold: true
                            }
                        }
                    }
                    Repeater {
                        model: root.heatRows
                        delegate: Row {
                            id: kanaHeatRow
                            required property var modelData
                            width: parent.width
                            spacing: 8
                            Column {
                                width: root.rowHeadW
                                height: 52
                                spacing: 2
                                Text {
                                    text: kanaHeatRow.modelData.short
                                    color: Theme.text
                                    font.family: Theme.fontBody
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Text {
                                    text: (kanaHeatRow.modelData.group || "").toUpperCase()
                                    color: Theme.textMuted
                                    font.family: Theme.fontBody
                                    font.pixelSize: 10
                                }
                            }
                            Repeater {
                                model: kanaHeatRow.modelData.cells || []
                                delegate: Item {
                                    required property var modelData
                                    width: Math.min(88, Math.max(36, (kanaHeatRow.width - root.rowHeadW - root.heatCols * 8) / root.heatCols))
                                    height: 52
                                    HeatMark {
                                        visible: modelData.id !== ""
                                        width: parent.width
                                        height: parent.height
                                        glyph: root.cellGlyph(modelData)
                                        status: modelData.status || "unlearned"
                                        reading: modelData.reading || ""
                                        onHovered: root.heatNote = glyph + "  " + reading.toUpperCase() + "  ·  " + root.statusName(status)
                                    }
                                }
                            }
                        }
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 8
                    visible: root.vocabHeat && root.vocabList.length > 0
                    Repeater {
                        model: root.vocabList
                        delegate: HeatMark {
                            required property var modelData
                            width: 108
                            height: 64
                            glyph: modelData.glyph || ""
                            gloss: modelData.gloss || ""
                            status: modelData.status || "unlearned"
                            onHovered: root.heatNote = glyph + (gloss ? "  " + gloss : "") + "  ·  " + root.statusName(status)
                        }
                    }
                }

                Text {
                    visible: root.vocabHeat && root.vocabList.length === 0
                    text: "还没有词汇。"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Text {
                    visible: !root.vocabHeat && !root.heatBoard
                    text: "这张表还没有排出来。"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
            }
        }
    }

    property string heatNote: "颜色对应掌握程度。悬停一个字可以看读音。"
}
