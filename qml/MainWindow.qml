import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls.Basic
import LuckyWheel

ApplicationWindow {
    id:mainWindow
    visible: true
    title: qsTr("幸运大转盘")
    minimumWidth: 800
    minimumHeight: 600
    flags: Qt.Window | Qt.FramelessWindowHint
    JsonParser {
        id:jsonParser
    }
    Component.onCompleted: {
        //直接接函数的返回值的话，rollingLottery.guestNames中的值类型都是QString
        //会提示JavaScript函数不支持QString
        //这样中间导一手QML会将QString转换成string
        var stringArray = jsonParser.getGuestNames()
        rollingLottery.guestNames = stringArray
        stringArray = jsonParser.getVipNames()
        rollingLottery.vipNames = stringArray

        var jsonString = jsonParser.getWheelPrizesList();
        wheelItem.wheelPrizesList = JSON.parse(jsonString)
    }

    enum WindowPage{
        Wheel,
        RollingLottery
    }
    property int currentPage: MainWindow.WindowPage.Wheel
    onCurrentPageChanged: {
        if(currentPage === MainWindow.WindowPage.Wheel) {
            rollingLottery.rolling = false;
            rollingLottery.visible = false;
            wheelItem.wheelVisible = true;
            lotterySeatCountButton.visible = false;
        } else if(currentPage === MainWindow.WindowPage.RollingLottery) {
            wheelItem.wheelVisible = false;
            rollingLottery.visible = true
            lotterySeatCountButton.visible = true
        }
    }

    //背景
    Image {
        anchors.fill: parent
        source: "../image/pexels-ifreestock-695971.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    //按钮组
    RowLayout {
        id:buttonGroup
        anchors.leftMargin:20
        anchors.topMargin:20
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 15

        Button {
            Layout.preferredHeight:40
            Layout.preferredWidth:40
            onClicked: {mainWindow.showFullScreen(); mouseIdleTimer.restart();}
            background:Image {
                source:  "../image/全屏.png"
            }
        }
        Button {
            Layout.preferredHeight:40
            Layout.preferredWidth:40
            onClicked: {mainWindow.showNormal(); mouseIdleTimer.restart();}
            background:Image {
                source:  "../image/还原画布.png"
            }
        }
        Button {
            Layout.preferredHeight:40
            Layout.preferredWidth:40
            onClicked: {
                mouseIdleTimer.restart();
                if(mainWindow.currentPage === MainWindow.WindowPage.Wheel) {
                    mainWindow.currentPage = MainWindow.WindowPage.RollingLottery
                } else if (mainWindow.currentPage === MainWindow.WindowPage.RollingLottery) {
                    mainWindow.currentPage = MainWindow.WindowPage.Wheel
                }
            }
            background:Image {
                source:  "../image/切换.png"
            }
        }
        Button {
            visible:false
            id:lotterySeatCountButton
            Layout.preferredHeight:40
            Layout.preferredWidth:40
            onClicked: {
                mouseIdleTimer.restart();
                if(rollingLottery.lotterySeatCount >= rollingLottery.lotterySeatMaxCount) {
                    rollingLottery.lotterySeatCount = 1
                    return
                }
                rollingLottery.lotterySeatCount++
            }
            background:Image {
                source:  "../image/调试.png"
            }
        }
        Button {
            Layout.preferredHeight:40
            Layout.preferredWidth:40
            onClicked: mainWindow.showMinimized()
            background:Image {
                source:  "../image/最小化.png"
            }
        }
        Button {
            Layout.preferredHeight:40
            Layout.preferredWidth:40
            onClicked: mainWindow.close();
            background:Image {
                source:  "../image/关闭.png"
            }
        }
    }

    //滚动抽奖
    RollingLottery {
        visible:false
        width: parent.width * 0.6
        height: parent.height
        anchors.left:parent.left
        //activateVipPower:true
        id:rollingLottery
    }

    //转盘
    Wheel {
        id:wheelItem
        width: parent.width * 0.6
        height: parent.height
        anchors.left:parent.left
        speedUpTime: 1000
        friction:0.97
        //presetWinningSlice: 2  //预设中奖结果
    }
    //转盘阴影效果
      MultiEffect {
          source: wheelItem
          anchors.fill: wheelItem
          shadowEnabled: true
          shadowColor:"white"
          blur:1.0
          blurMax:48
      }

    //3秒不动鼠标则隐藏鼠标指针
    Timer {
        id: mouseIdleTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            buttonGroup.visible = false
            mouseTracker.cursorShape = Qt.BlankCursor
            stop()
        }
    }

    //全局鼠标区域
    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled:true
        acceptedButtons:Qt.NoButton
        onPositionChanged: {
            buttonGroup.visible = true
            mouseTracker.cursorShape = Qt.ArrowCursor
            mouseIdleTimer.restart();
        }
    }

    //全局键盘区域，用来接收键盘事件
    FocusScope {
        //全局唯一，获取键盘焦点，接收键盘事件
        focus:true
        onActiveFocusChanged: {
            if (!activeFocus) {
                forceActiveFocus(); // 强制重新设置焦点
            }
        }
        Keys.onSpacePressed: {
            //空格启动滚动或转盘
            if(mainWindow.currentPage === MainWindow.WindowPage.Wheel) {
                wheelItem.startSpinning()
            } else if (mainWindow.currentPage === MainWindow.WindowPage.RollingLottery) {
                rollingLottery.rolling = !rollingLottery.rolling
            }
        }
        Keys.onEscapePressed : {
            //ESC关闭vip或转盘随机
            if(mainWindow.currentPage === MainWindow.WindowPage.RollingLottery) {
                rollingLottery.activateVipPower = false
                console.log("deactivate vip")
            } else if (mainWindow.currentPage === MainWindow.WindowPage.Wheel) {
                wheelItem.presetWinningSlice = -1
                console.log("random prizes")
            }
        }
        Keys.onPressed: (event)=> {
            //F1开启vip，F1~F12选择转盘奖品
            if (event.key == Qt.Key_F1) {
                if(mainWindow.currentPage === MainWindow.WindowPage.RollingLottery) {
                    rollingLottery.activateVipPower = true
                    console.log("activate vip")
                }
            }
            if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
                if (mainWindow.currentPage === MainWindow.WindowPage.Wheel) {
                    const presetIndex = event.key - Qt.Key_F1;
                    if (wheelItem.wheelPrizesList.length < presetIndex + 1) {
                        console.log("Invalid value");
                        return;
                    }
                    wheelItem.presetWinningSlice = presetIndex;
                    console.log("preset prizes : " + wheelItem.wheelPrizesList[presetIndex].name);
                }
            }
        }
    }
}

