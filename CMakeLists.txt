cmake_minimum_required(VERSION 3.21)
project(Sonora VERSION 0.2.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickControls2 Multimedia)

qt_standard_project_setup(REQUIRES 6.5)

set(SONORA_SOURCES
    src/main.cpp
    src/app/AppController.cpp
    src/audio/AudioEngine.cpp
    src/library/SoundLibrary.cpp
    src/library/SoundFilterModel.cpp
    src/library/PlaylistModel.cpp
    src/hotkeys/HotkeyManager.cpp
    src/theme/ThemeEngine.cpp
)

if(WIN32)
    list(APPEND SONORA_SOURCES src/hotkeys/HotkeyBackendWin.cpp)
endif()

qt_add_executable(Sonora ${SONORA_SOURCES})

target_include_directories(Sonora PRIVATE src)

target_link_libraries(Sonora PRIVATE
    Qt6::Core Qt6::Gui Qt6::Widgets
    Qt6::Qml Qt6::Quick Qt6::QuickControls2
    Qt6::Multimedia
)

# QML module
qt_add_qml_module(Sonora
    URI Sonora
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qmlmodule/Sonora
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/Icons.qml
        qml/NavRail.qml
        qml/NavItem.qml
        qml/MasterBar.qml
        qml/LibraryPage.qml
        qml/PlaylistsPage.qml
        qml/PlayerPage.qml
        qml/SettingsPage.qml
        qml/SoundCard.qml
        qml/MdButton.qml
        qml/MdChip.qml
        qml/MdIcon.qml
        qml/MdIconButton.qml
        qml/MdSearchBar.qml
        qml/MdSegmented.qml
        qml/MdSlider.qml
        qml/MdSwitch.qml
        qml/MdText.qml
)

# Core singleton for AppController bridge
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/Icons.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

install(TARGETS Sonora BUNDLE DESTINATION . RUNTIME DESTINATION bin)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/packaging/sonora.desktop
        DESTINATION share/applications)
install(DIRECTORY ${CMAKE_BINARY_DIR}/qmlmodule/Sonora
        DESTINATION share/sonora/qml)
