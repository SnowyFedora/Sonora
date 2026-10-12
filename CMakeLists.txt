cmake_minimum_required(VERSION 3.21)
project(Sonora VERSION 0.2.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickControls2 Multimedia)
qt_standard_project_setup(REQUIRES 6.6)

if(QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_executable(Sonora WIN32 MACOSX_BUNDLE
    src/main.cpp
    src/app/AppController.h          src/app/AppController.cpp
    src/theme/ThemeEngine.h          src/theme/ThemeEngine.cpp
    src/library/Sound.h
    src/library/SoundLibrary.h       src/library/SoundLibrary.cpp
    src/library/SoundFilterModel.h   src/library/SoundFilterModel.cpp
    src/audio/AudioEngine.h          src/audio/AudioEngine.cpp
    src/hotkeys/IHotkeyBackend.h
    src/hotkeys/HotkeyManager.h      src/hotkeys/HotkeyManager.cpp
)

set_source_files_properties(qml/Theme.qml qml/Icons.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(Sonora
    URI Sonora
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qmlmodule/Sonora
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/Icons.qml
        qml/MdText.qml
        qml/MdIcon.qml
        qml/MdIconButton.qml
        qml/MdButton.qml
        qml/MdChip.qml
        qml/MdSearchBar.qml
        qml/MdSlider.qml
        qml/MdSegmented.qml
        qml/MdSwitch.qml
        qml/NavItem.qml
        qml/NavRail.qml
        qml/MasterBar.qml
        qml/SoundCard.qml
        qml/LibraryPage.qml
        qml/PlaylistsPage.qml
        qml/PlayerPage.qml
        qml/SettingsPage.qml
)

target_include_directories(Sonora PRIVATE src)

target_link_libraries(Sonora PRIVATE
    Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia)

if(WIN32)
    target_sources(Sonora PRIVATE src/hotkeys/HotkeyBackendWin.cpp)
    target_link_libraries(Sonora PRIVATE user32)
endif()

install(TARGETS Sonora BUNDLE DESTINATION . RUNTIME DESTINATION bin)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/packaging/sonora.desktop
        DESTINATION share/applications)
install(DIRECTORY ${CMAKE_BINARY_DIR}/qmlmodule/Sonora
        DESTINATION share/sonora/qml
        PATTERN "*.qmltypes" EXCLUDE)
