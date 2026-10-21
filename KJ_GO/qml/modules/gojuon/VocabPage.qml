import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    property string setId: "ko-vocab"
    property string language: "ko"
    property string statusFilter: "all"
    property string groupFilter: "all"
    property string selectedId: ""
    property string loadedId: ""
    property bool loadingEditor: false
    property bool ready: false

    readonly property var catalog: {
        var rev = studyStore.revision
        return studyStore.items(root.setId)
    }
    readonly property var groupNames: {
        var names = []
        var rows = root.catalog
        for (var i = 0; i < rows.length; ++i) {
            var name = rows[i].group
            if (name && names.indexOf(name) < 0)
                names.push(name)
        }
        return names
    }
    readonly property var visibleRows: {
        var out = []
        var rows = root.catalog
        for (var i = 0; i < rows.length; ++i) {
            var row = rows[i]
            if (root.groupFilter !== "all" && row.group !== root.groupFilter)
                continue
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

    function commitEditor(id) {
        if (!ready || loadingEditor || !id)
            return
        studyStore.setFields(id, {
            gloss: glossEdit.text,
            example: exampleEdit.text,
            exampleGloss: exampleGlossEdit.text,
            note: noteEdit.text,
            mnemonic: mnemonicEdit.text
        })
    }

    function loadEditor() {
        if (!ready)
            return
        loadingEditor = true
        var card = root.selectedId ? studyStore.item(root.selectedId) : null
        glossEdit.text = card && card.gloss ? card.gloss : ""
        exampleEdit.text = card && card.example ? card.example : ""
        exampleGlossEdit.text = card && card.exampleGloss ? card.exampleGloss : ""
        noteEdit.text = card && card.note ? card.note : ""
        mnemonicEdit.text = card && card.mnemonic ? card.mnemonic : ""
        loadedId = root.selectedId
        loadingEditor = false
    }

    function choose(id) {
        if (id === selectedId)
            return
        if (loadedId)
            commitEditor(loadedId)
        loadedId = ""
        selectedId = id
    }

    onSelectedIdChanged: loadEditor()
    onSetIdChanged: {
        statusFilter = "all"
        groupFilter = "all"
        if (loadedId)
            commitEditor(loadedId)
        loadedId = ""
        var next = catalog.length > 0 ? catalog[0].id : ""
        if (next === selectedId)
            loadEditor()
        else
            selectedId = next
    }
    onVisibleChanged: {
        if (!visible && loadedId)
            commitEditor(loadedId)
    }
    Component.onCompleted: {
        ready = true
        if (!selectedId && catalog.length > 0)
            selectedId = catalog[0].id
        else
            loadEditor()
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

    component EditorBlock: Column {
        id: block
        property string label: ""
        property alias text: area.text
        property string placeholder: ""
        property int boxHeight: 72
        spacing: 6
        width: parent.width
        Text {
            text: block.label
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 10
            font.letterSpacing: 1.8
        }
        TextArea {
            id: area
            width: parent.width
            height: block.boxHeight
            topPadding: 8
            bottomPadding: 8
            leftPadding: 0
            rightPadding: 0
            wrapMode: TextArea.Wrap
            placeholderText: block.placeholder
            color: Theme.text
            placeholderTextColor: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 15
            background: Item {
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: area.activeFocus ? Theme.text : Theme.border
                }
            }
            onEditingFinished: root.commitEditor(root.loadedId)
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
                    text: "VOCAB · 词汇"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2.4
                }
                Text {
                    text: "词汇"
                    color: Theme.text
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.title
                    font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            Row {
                Layout.alignment: Qt.AlignBottom
                spacing: 4
                visible: root.catalog.length > 0
                ChoiceChip { label: "全部"; chosen: root.statusFilter === "all"; onPicked: root.statusFilter = "all" }
                ChoiceChip { label: "已掌握"; ink: Theme.primary; chosen: root.statusFilter === "mastered"; onPicked: root.statusFilter = "mastered" }
                ChoiceChip { label: "模糊"; ink: Theme.textMuted; chosen: root.statusFilter === "fuzzy"; onPicked: root.statusFilter = "fuzzy" }
                ChoiceChip { label: "未掌握"; ink: Theme.accent; chosen: root.statusFilter === "unlearned"; onPicked: root.statusFilter = "unlearned" }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4
            visible: root.groupNames.length > 0
            ChoiceChip { label: "全部"; chosen: root.groupFilter === "all"; onPicked: root.groupFilter = "all" }
            Repeater {
                model: root.groupNames
                delegate: ChoiceChip {
                    required property string modelData
                    label: modelData
                    chosen: root.groupFilter === modelData
                    onPicked: root.groupFilter = modelData
                }
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
                spacing: 12
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
                    text: "词写进词库之后，会显示在这里。释义、例句、用法和笔记都可以改，闪卡读的是同一份。"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
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
                            text: row.modelData.gloss
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
                            text: root.entry && root.entry.pos ? root.entry.pos : ""
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 13
                        }
                        Text {
                            text: root.entry && root.entry.group ? root.entry.group : ""
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

                    EditorBlock {
                        id: glossEdit
                        label: "释义"
                        placeholder: "这个词的中文意思"
                        boxHeight: 56
                    }
                    EditorBlock {
                        id: exampleEdit
                        label: "例句"
                        placeholder: "写一句你自己会说的"
                        boxHeight: 84
                    }
                    EditorBlock {
                        id: exampleGlossEdit
                        label: "译文"
                        placeholder: "这句话的中文"
                        boxHeight: 64
                    }
                    EditorBlock {
                        id: noteEdit
                        label: "用法"
                        placeholder: "它和相近的说法差在哪"
                        boxHeight: 84
                    }
                    EditorBlock {
                        id: mnemonicEdit
                        label: "笔记"
                        placeholder: "只留给自己的提醒"
                        boxHeight: 72
                    }

                    Column {
                        width: parent.width
                        spacing: 10
                        visible: root.entry && root.entry.lookalikes && root.entry.lookalikes.length > 0
                        Text {
                            text: "相近"
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                        }
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: root.entry && root.entry.lookalikes ? root.entry.lookalikes : []
                                delegate: Rectangle {
                                    id: likeChip
                                    required property var modelData
                                    implicitWidth: likeText.implicitWidth + 20
                                    implicitHeight: 36
                                    radius: Theme.radiusSm
                                    color: likeHover.hovered ? Theme.muted : "transparent"
                                    border.width: 1
                                    border.color: Theme.line
                                    Text {
                                        id: likeText
                                        anchors.centerIn: parent
                                        text: likeChip.modelData.glyph + "  " + likeChip.modelData.gloss
                                        color: Theme.text
                                        font.family: Theme.fontBody
                                        font.pixelSize: 13
                                    }
                                    HoverHandler { id: likeHover }
                                    TapHandler { onTapped: root.choose(likeChip.modelData.id) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
