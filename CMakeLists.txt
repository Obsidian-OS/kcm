cmake_minimum_required(VERSION 3.22)
project(kcm_obsidianos VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(QT_MIN_VERSION "6.6.0")
set(KF_MIN_VERSION "6.0.0")
find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)
find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    DBus
)

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons
    I18n
    KCMUtils
    Config
)

kcmutils_add_qml_kcm(kcm_obsidianos)
target_sources(kcm_obsidianos PRIVATE
    src/kcm/obsidianoskcm.cpp
    src/kcm/obsidianoskcm.h
    src/kcm/backupmanager.cpp
    src/kcm/backupmanager.h
    src/kcm/slotmanager.cpp
    src/kcm/slotmanager.h
    src/kcm/updatemanager.cpp
    src/kcm/updatemanager.h
    src/kcm/environmentmanager.cpp
    src/kcm/environmentmanager.h
)

target_link_libraries(kcm_obsidianos PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
    KF6::CoreAddons
    KF6::I18n
    KF6::KCMUtilsQuick
    KF6::ConfigCore
)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
