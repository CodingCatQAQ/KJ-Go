import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../modules/gojuon"

Item {
    id: root
    property int currentModule: 0
    property string studyView: "overview"
    property bool katakana: false
    property string selectedRomaji: "a"
    property string filter: "all"
    property var weakList: ["nu", "me", "ne"]
    property var mastery: KanaCatalog.initialMastery()

    readonly property var counts: KanaCatalog.counts(mastery)
    readonly property var selectedEntry: KanaCatalog.find(katakana, selectedRomaji)

    function showStudy(view) {
        currentModule = 0
        studyView = view
    }

    function openDetail(romaji) {
        selectedRomaji = romaji
        showStudy("detail")
    }

    function copyMastery() {
        var next = {}
        for (var key in mastery)
            next[key] = mastery[key]
        return next
    }

    function markWeak() {
        if (weakList.indexOf(selectedRomaji) < 0) {
            var nextWeak = weakList.slice()
            nextWeak.unshift(selectedRomaji)
            weakList = nextWeak
        }
        var next = copyMastery()
        next[selectedRomaji] = "learning"
        mastery = next
    }

    function rateCard(romaji, score) {
        var next = copyMastery()
        next[romaji] = score === 3 ? "mastered" : "learning"
        mastery = next
        if (score === 1 && weakList.indexOf(romaji) < 0) {
            var added = weakList.slice()
            added.unshift(romaji)
            weakList = added
        }
        if (score === 3)
            weakList = weakList.filter(function (item) { return item !== romaji })
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    AppTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        currentIndex: root.currentModule
        onNavigate: {
            root.currentModule = index
            if (index === 0)
                root.studyView = "overview"
        }
        onToggleTheme: Theme.dark = !Theme.dark
        onOpenSettings: settingsPopup.open()
    }

    AppSideBar {
        id: sideBar
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Theme.sideBarW
        module: root.currentModule
        studyView: root.studyView
        filter: root.filter
        counts: root.counts
        weakCount: root.weakList.length
        selectedChar: root.selectedEntry ? root.selectedEntry.char : "あ"
        onOpenStudy: root.showStudy(view)
        onPickFilter: root.filter = id
    }

    StackLayout {
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: sideBar.right
        anchors.right: parent.right
        currentIndex: root.currentModule

        Item {
            KanaOverviewPage {
                anchors.fill: parent
                visible: root.studyView === "overview"
                katakana: root.katakana
                filter: root.filter
                mastery: root.mastery
                onToggleScript: root.katakana = katakana
                onOpenDetail: root.openDetail(romaji)
            }
            KanaDetailPage {
                anchors.fill: parent
                visible: root.studyView === "detail"
                katakana: root.katakana
                romaji: root.selectedRomaji
                mastery: root.mastery[root.selectedRomaji] || "new"
                weak: root.weakList.indexOf(root.selectedRomaji) >= 0
                onBack: root.showStudy("overview")
                onStep: root.selectedRomaji = KanaCatalog.step(root.selectedRomaji, direction)
                onMarkWeak: root.markWeak()
            }
        }
        FlashcardPage {
            mastery: root.mastery
            weakList: root.weakList
            onRate: root.rateCard(romaji, score)
            onExit: root.showStudy("overview")
        }
        ModulePlaceholder {
            title: "游戏"
            kana: "遊"
            note: "假名打地鼠、听音辨字等小游戏将在第二期加入。"
        }
        ModulePlaceholder {
            title: "进度"
            kana: "進"
            note: "学习曲线、记忆保持率与弱项热力图将在第二期加入。"
        }
    }

    Popup {
        id: settingsPopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 320
        padding: 24
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: Theme.surface
            radius: 12
            border.color: Theme.border
            border.width: 1
        }
        contentItem: Column {
            spacing: 16
            Text { text: "设置"; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 24; font.bold: true }
            Text { text: "外观跟随顶栏的日月按钮，也可以在这里切换。"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 13; wrapMode: Text.WordWrap; width: 272 }
            Rectangle {
                width: 160
                height: 40
                radius: Theme.radiusMd
                color: "transparent"
                border.width: 1
                border.color: Theme.line
                Text {
                    anchors.centerIn: parent
                    text: Theme.dark ? "切换到浅色" : "切换到深色"
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                TapHandler { onTapped: Theme.dark = !Theme.dark }
            }
            Text {
                text: "关闭"
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 14
                TapHandler { onTapped: settingsPopup.close() }
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: root.studyView === "detail" || root.currentModule === 1
        onActivated: root.showStudy("overview")
    }
    Shortcut {
        sequence: "Left"
        enabled: root.currentModule === 0 && root.studyView === "detail"
        onActivated: root.selectedRomaji = KanaCatalog.step(root.selectedRomaji, -1)
    }
    Shortcut {
        sequence: "Right"
        enabled: root.currentModule === 0 && root.studyView === "detail"
        onActivated: root.selectedRomaji = KanaCatalog.step(root.selectedRomaji, 1)
    }
    Shortcut {
        sequence: "Tab"
        enabled: root.currentModule === 0
        onActivated: root.katakana = !root.katakana
    }
}
