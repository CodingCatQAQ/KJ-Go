cmake_minimum_required(VERSION 3.16)

project(KJ_GO VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appKJ_GO
    main.cpp
)

set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)
set_source_files_properties(qml/modules/gojuon/KanaCatalog.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appKJ_GO
    URI KJ_GO
    NO_GENERATE_EXTRA_QMLDIRS
    QML_FILES
        qml/Main.qml
        qml/shell/AppShell.qml
        qml/shell/AppTopBar.qml
        qml/shell/AppSideBar.qml
        qml/shell/ModulePlaceholder.qml
        qml/theme/Theme.qml
        qml/theme/LightPalette.qml
        qml/theme/DarkPalette.qml
        qml/components/KanaCell.qml
        qml/components/ScriptToggle.qml
        qml/components/Kbd.qml
        qml/modules/gojuon/KanaCatalog.qml
        qml/modules/gojuon/KanaOverviewPage.qml
        qml/modules/gojuon/KanaDetailPage.qml
        qml/modules/gojuon/FlashcardPage.qml
        qml/modules/gojuon/WeakQueuePage.qml
    RESOURCES
        qml/theme/qmldir
        qml/shell/qmldir
        qml/components/qmldir
        qml/modules/gojuon/qmldir
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appKJ_GO PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appKJ_GO
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appKJ_GO
    PRIVATE Qt6::Quick
)

install(TARGETS appKJ_GO
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
