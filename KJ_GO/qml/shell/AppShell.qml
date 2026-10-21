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
    property string language: "ja"
    property string flashQueue: "today"
    property string flashFront: "hira"

    readonly property string studySet: language === "ko" ? "ko-syllable" : "ja-seion"
    readonly property string vocabSet: language === "ko" ? "ko-vocab" : "ja-vocab"
    readonly property string flashSet: language === "ko" ? "ko-vocab" : "ja-seion"
    readonly property string activeSet: currentModule === 1 ? flashSet : (studyView === "vocab" ? vocabSet : studySet)
    readonly property var counts: {
        var rev = studyStore.revision
        return studyStore.counts(root.activeSet)
    }
    readonly property int weakCount: {
        var rev = studyStore.revision
        return studyStore.weakIds(root.activeSet).length
    }
    readonly property int reviewCount: {
        var rev = studyStore.revision
        return studyStore.reviewQueue(root.activeSet, 12).length
    }

    function showStudy(view) {
        currentModule = 0
        studyView = view
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    AppSideBar {
        id: sideBar
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Theme.sideBarW
        module: root.currentModule
        language: root.language
        studyView: root.studyView
        filter: root.filter
        counts: root.counts
        weakCount: root.weakCount
        reviewCount: root.reviewCount
        queueMode: root.flashQueue
        frontScript: root.flashFront
        onOpenStudy: root.showStudy(view)
        onPickFilter: root.filter = id
        onPickQueue: root.flashQueue = id
        onPickFront: root.flashFront = id
    }

    AppTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: sideBar.right
        anchors.right: parent.right
        currentIndex: root.currentModule
        language: root.language
        onToggleLanguage: {
            root.language = root.language === "ja" ? "ko" : "ja"
            if (root.language === "ko" && (root.flashFront === "hira" || root.flashFront === "kata"))
                root.flashFront = "word"
            else if (root.language === "ja" && (root.flashFront === "word" || root.flashFront === "gloss"))
                root.flashFront = "hira"
        }
        onNavigate: {
            root.currentModule = index
            if (index === 0)
                root.studyView = "overview"
        }
        onToggleTheme: Theme.dark = !Theme.dark
        onOpenSettings: settingsPopup.open()
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
                language: root.language
                katakana: root.katakana
                onToggleScript: root.katakana = katakana
            }
            KanaDetailPage {
                anchors.fill: parent
                visible: root.studyView === "detail"
                katakana: root.katakana
                romaji: root.selectedRomaji
                mastery: "new"
                weak: false
                onBack: root.showStudy("overview")
                onStep: root.selectedRomaji = KanaCatalog.step(root.selectedRomaji, direction)
            }
            VocabPage {
                anchors.fill: parent
                visible: root.studyView === "vocab"
                language: root.language
                setId: root.vocabSet
            }
        }
        FlashcardPage {
            setId: root.flashSet
            queueMode: root.flashQueue
            frontScript: root.flashFront
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
