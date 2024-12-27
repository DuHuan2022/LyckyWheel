cmake_minimum_required(VERSION 3.16)

project(LuckyWheel VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appLuckyWheel
    main.cpp
)

qt_add_qml_module(appLuckyWheel
    URI LuckyWheel
    VERSION 1.0
    QML_FILES
        qml/MainWindow.qml
        qml/Wheel.qml
        qml/RollingLottery.qml
    RESOURCES
        image/pexels-ifreestock-695971.jpg
        image/关闭.png
        image/最小化.png
        image/全屏.png
        image/还原画布.png
        image/切换.png
        image/调试.png
    SOURCES
        Tools/jsonparser.h
        Tools/jsonparser.cpp
)

include_directories(./Tools)
# qt_add_qml_module 的第一个参数是 backing target（后备目标）。
# 如果 backing target 是一个已有的静态库/动态库/可执行文件，
# qt_add_qml_module 会将 SOURCES 和 QML_FILES 等资源编译到该目标中，并链接到 Qt 的库。
# 如果 backing target 不存在，qt_add_qml_module 会自动创建一个目标（默认类型根据 Qt 构建方式为静态或动态库）。
# URI的名字对应生成路径，qt_add_qml_module会将一系列qml文件生成到这个路径中
# 比如URI是Tools.json，则生成路径应该设置为Tools/json，最终的产物也在这个路径
# QML import Tools.json的时候就会去Tools/json这个目录去找
#
# 以下代码的作用是：
# 1. 如果 backing target `Tools` 不存在，创建一个名为 `Tools` 的库。
# 2. 将 SOURCES 中指定的代码编译到 `Tools` 库中，并链接到 Qt 的库。
# 3. 生成一个 QML 模块 `Tools`，在 QML 中通过 `import Tools 1.0` 使用。
# 4. QML 模块的元信息（如 qmldir 文件）将生成到指定的 OUTPUT_DIRECTORY。

# qt_add_qml_module(Tools
#     URI Tools
#     VERSION 1.0
#     SOURCES
#         Tools/jsonparser.h
#         Tools/jsonparser.cpp
#     OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Tools"
# )

#update:
#后来发现，不需要qt_add_qml_module一个新的backup target，直接加到主模块里，然后import LuckyWheel就可以用

#其实QML的模块的意义，就是把C++库的接口暴露到QML中，
#qt_add_qml_module(appLuckyWheel的作用：
#1.将后面的一大串资源，qml，代码都编译进可执行文件
#2.暴露接口到LuckyWheel模块

#update:QtCreator 15.0.0，Qt6.8.1，QML Language Server还在开发中，有Bug，import命令会提示找不到模块，但实际上运行正常

# Qtfor iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appLuckyWheel PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appLuckyWheel
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appLuckyWheel
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appLuckyWheel
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
