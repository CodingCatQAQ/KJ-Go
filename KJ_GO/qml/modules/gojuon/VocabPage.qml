import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    property string setId: "ko-vocab"
    property string language: "ko"
    property string statusFilter: "all"
    property string selectedId: ""
    property string formId: ""
    property string formPos: ""
    property string posHintLabel: ""
    property string formError: ""
    property string deleteError: ""

    readonly property var catalog: {
        var rev = studyStore.revision
        return studyStore.items(root.setId)
    }
    readonly property var visibleRows: {
        var out = []
        var rows = root.catalog
        for (var i = 0; i < rows.length; ++i) {
            var row = rows[i]
            if (root.statusFilter !== "all" && row.status !== root.statusFilter)
                continue
            out.push(row)
        }
        return out
    }
    readonly property var entry: {
        var rev = studyStore.revision
        return root.selectedId ? studyStore.item(root.selectedId) : null
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

    function heroSize(text) {
        var n = text ? text.length : 1
        if (n <= 2)
            return 72
        if (n <= 6)
            return 48
        if (n <= 10)
            return 32
        return 24
    }

    function neighborId(id) {
        var rows = root.visibleRows
        for (var i = 0; i < rows.length; ++i) {
            if (rows[i].id !== id)
                continue
            if (i + 1 < rows.length)
                return rows[i + 1].id
            if (i > 0)
                return rows[i - 1].id
            return ""
        }
        return ""
    }

    function fillForm(card) {
        formError = ""
        posHintLabel = ""
        wordInput.text = card && card.glyph ? card.glyph : ""
        var written = card && card.pos ? card.pos : ""
        formPos = PosCatalog.find(written) ? written : "其他"
        glossInput.text = card && card.gloss ? card.gloss : ""
        exampleInput.text = card && card.example ? card.example : ""
        mnemonicInput.text = card && card.mnemonic ? card.mnemonic : ""
    }

    function pickPos(label) {
        formPos = label
    }

    function shownPos(written) {
        return PosCatalog.find(written) ? written : "其他"
    }

    function posHintText(label) {
        var kind = PosCatalog.find(label)
        return kind ? kind.note : ""
    }

    function openAdd() {
        formId = ""
        fillForm(null)
        editorPopup.open()
    }

    function openEdit() {
        if (!entry || !entry.id)
            return
        formId = entry.id
        fillForm(entry)
        editorPopup.open()
    }

    function formFields() {
        return {
            glyph: wordInput.text,
            pos: root.shownPos(formPos),
            gloss: glossInput.text,
            example: exampleInput.text,
            mnemonic: mnemonicInput.text
        }
    }

    function saveForm() {
        if (!wordInput.text.trim()) {
            formError = "先写下这个词"
            wordInput.input.forceActiveFocus()
            return
        }
        if (!glossInput.text.trim()) {
            formError = "中文意思不能空着"
            glossInput.input.forceActiveFocus()
            return
        }
        var issue = studyStore.scriptIssue(language, wordInput.text)
        if (issue) {
            formError = issue
            wordInput.input.forceActiveFocus()
            return
        }
        if (formId) {
            if (!studyStore.updateVocab(formId, formFields())) {
                formError = "没有保存"
                return
            }
            editorPopup.close()
            return
        }
        var id = studyStore.addVocab(setId, language, formFields())
        if (!id) {
            formError = "没有写入词库"
            return
        }
        statusFilter = "all"
        selectedId = id
        editorPopup.close()
    }

    function openDelete() {
        if (!entry || !entry.id)
            return
        deleteError = ""
        deletePopup.open()
    }

    function removeSelected() {
        var id = selectedId
        if (!id)
            return
        var next = neighborId(id)
        if (!studyStore.removeVocab(id)) {
            deleteError = "没有删掉"
            return
        }
        deletePopup.close()
        selectedId = next
    }

    function choose(id) {
        if (id !== selectedId)
            selectedId = id
    }

    onSetIdChanged: {
        statusFilter = "all"
        editorPopup.close()
        deletePopup.close()
        var next = catalog.length > 0 ? catalog[0].id : ""
        selectedId = next
    }
    onVisibleChanged: {
        if (!visible) {
            editorPopup.close()
            deletePopup.close()
        }
    }
    Component.onCompleted: {
        if (!selectedId && catalog.length > 0)
            selectedId = catalog[0].id
    }

    component ChoiceChip: Rectangle {
        id: chip
        property string label: ""
        property bool chosen: false
        property color ink: Theme.text
        signal picked()
        implicitWidth: chipLabel.implicitWidth + 20
        implicitHeight: 32
        radius: Theme.radiusSm
        color: chosen ? Theme.text : "transparent"
        Text {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.label
            color: chip.chosen ? Theme.bg : chip.ink
            font.family: Theme.fontBody
            font.pixelSize: 14
            font.bold: chip.chosen
        }
        TapHandler { onTapped: chip.picked() }
    }

    component PosChoice: Rectangle {
        id: posChip
        property string kindLabel: ""
        property bool chosen: false
        signal picked()
        implicitWidth: posChipText.implicitWidth + 22
        implicitHeight: 34
        radius: Theme.radiusSm
        color: chosen ? Theme.text : (posChipHover.hovered ? Theme.muted : "transparent")
        border.width: chosen ? 0 : 1
        border.color: Theme.line
        Text {
            id: posChipText
            anchors.centerIn: parent
            text: posChip.kindLabel
            color: posChip.chosen ? Theme.bg : Theme.text
            font.family: Theme.fontBody
            font.pixelSize: 14
            font.bold: posChip.chosen
        }
        HoverHandler {
            id: posChipHover
            onHoveredChanged: {
                if (hovered)
                    root.posHintLabel = posChip.kindLabel
                else if (root.posHintLabel === posChip.kindLabel)
                    root.posHintLabel = ""
            }
        }
        TapHandler { onTapped: posChip.picked() }
    }

    component QuietButton: Rectangle {
        id: btn
        property string label: ""
        property bool filled: false
        property bool danger: false
        signal picked()
        implicitWidth: btnLabel.implicitWidth + 28
        implicitHeight: 36
        radius: Theme.radiusSm
        color: btn.filled ? Theme.text : (btn.danger && btnHover.hovered ? Theme.accent : (btnHover.hovered ? Theme.muted : "transparent"))
        border.width: btn.filled ? 0 : 1
        border.color: btn.danger ? Theme.accent : Theme.line
        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: btn.label
            color: btn.filled ? Theme.bg : (btn.danger ? (btnHover.hovered ? Theme.primaryFg : Theme.accent) : Theme.text)
            font.family: Theme.fontBody
            font.pixelSize: 14
            font.bold: true
        }
        HoverHandler { id: btnHover }
        TapHandler { onTapped: btn.picked() }
    }

    component FormLine: Column {
        id: line
        property string label: ""
        property string placeholder: ""
        property int boxHeight: 40
        property string fontFamily: Theme.fontBody
        property int fontSize: 15
        property alias text: area.text
        property alias input: area
        spacing: 6
        Text {
            text: line.label
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 10
            font.letterSpacing: 1.8
        }
        TextArea {
            id: area
            width: line.width
            height: line.boxHeight
            topPadding: 8
            bottomPadding: 8
            leftPadding: 0
            rightPadding: 0
            wrapMode: TextArea.Wrap
            selectByMouse: true
            placeholderText: line.placeholder
            color: Theme.text
            placeholderTextColor: Theme.textMuted
            font.family: line.fontFamily
            font.pixelSize: line.fontSize
            background: Item {
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: area.activeFocus ? Theme.text : Theme.border
                }
            }
        }
    }

    component DetailBlock: Column {
        id: block
        property string label: ""
        property string value: ""
        spacing: 6
        width: parent.width
        Text {
            text: block.label
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 10
            font.letterSpacing: 1.8
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: block.value ? block.value : "还没写"
            color: block.value ? Theme.text : Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 15
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 40
        anchors.bottomMargin: 32
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            ColumnLayout {
                spacing: 8
                Text {
                    text: root.language === "ko" ? "단어" : "単語"
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.title
                    font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            Row {
                Layout.alignment: Qt.AlignBottom
                spacing: 8
                visible: root.catalog.length > 0
                QuietButton { label: "添加"; onPicked: root.openAdd() }
                Item { width: 8; height: 1 }
                ChoiceChip { label: "全部"; chosen: root.statusFilter === "all"; onPicked: root.statusFilter = "all" }
                ChoiceChip { label: "已掌握"; ink: Theme.primary; chosen: root.statusFilter === "mastered"; onPicked: root.statusFilter = "mastered" }
                ChoiceChip { label: "模糊"; ink: Theme.textMuted; chosen: root.statusFilter === "fuzzy"; onPicked: root.statusFilter = "fuzzy" }
                ChoiceChip { label: "未掌握"; ink: Theme.accent; chosen: root.statusFilter === "unlearned"; onPicked: root.statusFilter = "unlearned" }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.catalog.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 16
                width: 420
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "词表还是空的"
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: 36
                    font.bold: true
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "遇到一个词，把它和中文意思一起记进来。笔记可以写下这个词的特殊之处。"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Item {
                    width: parent.width
                    height: emptyAdd.implicitHeight
                    QuietButton {
                        id: emptyAdd
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: "添加"
                        filled: true
                        onPicked: root.openAdd()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.catalog.length > 0
            spacing: 36

            ListView {
                id: wordList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 460
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 4
                model: root.visibleRows
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: wordList.width
                    height: 64
                    radius: Theme.radiusMd
                    color: modelData.id === root.selectedId ? Theme.muted : (rowHover.hovered ? Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.45) : "transparent")

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: statusDot.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            width: parent.width
                            text: row.modelData.glyph
                            color: Theme.text
                            font.family: Theme.fontDisplay
                            font.pixelSize: 20
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: row.modelData.gloss ? row.modelData.gloss : "还没写释义"
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        id: statusDot
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: root.statusColor(row.modelData.status)
                    }
                    HoverHandler { id: rowHover }
                    TapHandler { onTapped: root.choose(row.modelData.id) }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.visibleRows.length === 0
                    text: "这个范围里还没有词"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
            }

            Flickable {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: detail.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: root.entry && root.entry.id
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: detail
                    width: parent.width
                    spacing: 22

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.entry ? root.entry.glyph : ""
                        color: Theme.text
                        font.family: Theme.fontDisplay
                        font.pixelSize: root.heroSize(text)
                        font.bold: true
                    }
                    Row {
                        spacing: 16
                        Text {
                            text: root.entry && root.entry.id ? root.shownPos(root.entry.pos) : ""
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 13
                        }
                        Text {
                            text: root.statusText(root.entry ? root.entry.status : "")
                            color: root.statusColor(root.entry ? root.entry.status : "")
                            font.family: Theme.fontBody
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    Row {
                        spacing: 8
                        QuietButton { label: "修改"; onPicked: root.openEdit() }
                        QuietButton { label: "删除"; danger: true; onPicked: root.openDelete() }
                    }

                    DetailBlock { label: "释义"; value: root.entry ? root.entry.gloss : "" }
                    DetailBlock { label: "例句"; value: root.entry ? root.entry.example : "" }
                    DetailBlock { label: "笔记"; value: root.entry ? root.entry.mnemonic : "" }
                }
            }
        }
    }

    Popup {
        id: editorPopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 440
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: wordInput.input.forceActiveFocus()
        onClosed: root.posHintLabel = ""
        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusXl
            border.color: Theme.border
            border.width: 1
        }
        contentItem: Item {
            implicitWidth: 440
            implicitHeight: Math.min(formColumn.implicitHeight + 56, 680)
            Flickable {
                anchors.fill: parent
                anchors.margins: 28
                contentWidth: width
                contentHeight: formColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                Column {
                    id: formColumn
                    width: parent.width
                    spacing: 16
                    Text {
                        width: parent.width
                        visible: root.formId !== ""
                        wrapMode: Text.WordWrap
                        text: "改完会写回这一条，闪卡用的也是它。"
                        color: Theme.textMuted
                        font.family: Theme.fontBody
                        font.pixelSize: 13
                    }
                    FormLine {
                        id: wordInput
                        width: parent.width
                        label: "单词"
                        placeholder: "刚遇到的词"
                        fontFamily: Theme.fontDisplay
                        fontSize: 20
                        boxHeight: 48
                    }
                    Column {
                        id: posField
                        width: parent.width
                        spacing: 8
                        Text {
                            text: "词性"
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                        }
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: PosCatalog.kinds
                                delegate: Item {
                                    required property var modelData
                                    implicitWidth: choice.implicitWidth
                                    implicitHeight: choice.implicitHeight
                                    PosChoice {
                                        id: choice
                                        kindLabel: modelData.label
                                        chosen: root.formPos === modelData.label
                                        onPicked: root.pickPos(modelData.label)
                                    }
                                }
                            }
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: root.posHintText(root.posHintLabel || root.formPos)
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 13
                        }
                    }
                    FormLine {
                        id: glossInput
                        width: parent.width
                        label: "释义"
                        placeholder: "这个词的中文意思"
                    }
                    FormLine {
                        id: exampleInput
                        width: parent.width
                        label: "例句"
                        placeholder: "在这里添加例句"
                        boxHeight: 72
                    }
                    FormLine {
                        id: mnemonicInput
                        width: parent.width
                        label: "笔记"
                        placeholder: "可记录该词汇的特殊之处。"
                        boxHeight: 84
                    }
                    Text {
                        width: parent.width
                        visible: root.formError !== ""
                        text: root.formError
                        color: Theme.accent
                        font.family: Theme.fontBody
                        font.pixelSize: 13
                    }
                    Row {
                        spacing: 8
                        QuietButton { label: "取消"; onPicked: editorPopup.close() }
                        QuietButton { label: "保存"; filled: true; onPicked: root.saveForm() }
                    }
                }
            }
        }
    }

    Popup {
        id: deletePopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 360
        padding: 28
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusXl
            border.color: Theme.border
            border.width: 1
        }
        contentItem: Column {
            spacing: 16
            Text {
                text: "删除"
                color: Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: 28
                font.bold: true
            }
            Text {
                width: 304
                wrapMode: Text.WordWrap
                text: "从词库删掉「" + (root.entry && root.entry.glyph ? root.entry.glyph : "这个词") + "」？这条词的复习记录也会一起去掉。"
                color: Theme.text
                font.family: Theme.fontBody
                font.pixelSize: 15
            }
            Text {
                width: 304
                visible: root.deleteError !== ""
                text: root.deleteError
                color: Theme.accent
                font.family: Theme.fontBody
                font.pixelSize: 13
            }
            Row {
                spacing: 8
                QuietButton { label: "取消"; onPicked: deletePopup.close() }
                QuietButton { label: "删除"; danger: true; onPicked: root.removeSelected() }
            }
        }
    }
}
