import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

//滚动人名抽奖
Item {
    id: rollingLottery
    property var guestNames:[
        // "钱强", "钱丽娜", "孙芳", "冯宇航", "秦天宇", "朱秀英",
        // "秦思远", "尤志强", "郑敏", "周丽", "陈洋", "褚俊杰",
        // "秦芳", "尤梦婷", "李敏", "卫强", "蒋明", "韩芳",
        // "吴志强", "周明"
    ] // 普通名单
    property var vipNames: [
         // "朱丽娜", "吴和平"
    ] // vip名单，可以指定某次抽奖的结果必定出在这个范围内
    property bool rolling: false // 是否在滚动中
    property int lotterySeatCount: lotterySeats.children.length //当前几个抽奖位
    readonly property int lotterySeatMaxCount: lotterySeats.children.length //最多几个抽奖位
    property bool activateVipPower: false //激活vip的力量，抽奖只会抽到vip

    onRollingChanged: {
        if(rolling) {
            for (var i in lotterySeats.children) {
                lotterySeats.children[i].text = "- - -"
            }
            rollingTimer.start()
        } else {
            rollingTimer.stop()
            if(activateVipPower) {
                var combinedNames =vipNames
                var randomIndex = []
                // 提前确定需要生成的随机索引数量
                var nameCount = combinedNames.length;
                var limit = Math.min(rollingLottery.lotterySeatCount, nameCount);

                // 生成唯一随机索引
                while (randomIndex.length < limit) {
                    var index = Math.floor(Math.random() * nameCount);
                    if (!randomIndex.includes(index)) {
                        randomIndex.push(index);
                    }
                }

                // 设置名字或占位符
                var usedGuestIndices = []
                for (var i = 0; i < rollingLottery.lotterySeatCount; i++) {
                    if (i < limit) {
                        lotterySeats.visibleChildren[i].text = combinedNames[randomIndex[i]];
                    } else {
                        //这里不能空着，从guestNames中再随机取名字
                        var guestIndex
                        do {
                            guestIndex = Math.floor(Math.random() * guestNames.length)
                        }
                        while(usedGuestIndices.includes(guestIndex))
                        usedGuestIndices.push(guestIndex)
                        lotterySeats.visibleChildren[i].text = guestNames[guestIndex];
                    }
                }
            }
            //把抽到奖的人从数组里删去，保证他不会再被抽到
            for(var i in lotterySeats.visibleChildren) {
                var name = lotterySeats.visibleChildren[i].text;
                var vipIndex = rollingLottery.vipNames.indexOf(name);
                if (vipIndex !== -1) {
                    rollingLottery.vipNames.splice(vipIndex, 1);
                }

                var guestIndex = rollingLottery.guestNames.indexOf(name);
                if (guestIndex !== -1) {
                    rollingLottery.guestNames.splice(guestIndex, 1);
                }
            }
        }
    }
    onLotterySeatCountChanged: {
        if(lotterySeatCount < 1) {
            //到这里就返回了，最多递归1次
            lotterySeatCount = 1
            return
        } else if (lotterySeatCount > lotterySeats.children.length) {
            lotterySeatCount = lotterySeats.children.length
            //到这里就返回了，最多递归1次
            return
        }
        for(var i in lotterySeats.children) {
            lotterySeats.children[i].visible = false;
        }
        for(var i = 0; i < lotterySeatCount; i++) {
            lotterySeats.children[i].visible = true;
        }
    }

    //抽奖位
    RowLayout {
        id:lotterySeats
        anchors.centerIn:parent
        spacing: parent.width/8
        Text {
            text: "- - -"
            font.bold: true
            color: "white"
            Component.onCompleted: {
                font.pointSize = Qt.binding(function() {
                    return rollingLottery.width/20;
                })
            }
        }
        Text {
            text: "- - -"
            font.bold: true
            color: "white"
            Component.onCompleted: {
                font.pointSize = Qt.binding(function() {
                    return rollingLottery.width/20;
                })
            }
        }
        Text {
            text: "- - -"
            font.bold: true
            color: "white"
            Component.onCompleted: {
                font.pointSize = Qt.binding(function() {
                    return rollingLottery.width/20;
                })
            }
        }
    }
    //文字阴影
    MultiEffect {
        source: lotterySeats
        anchors.fill: lotterySeats
        shadowEnabled: true
        shadowColor:Qt.rgba(1.0, 0.8431, 0.0, 1.0)
        blur:1.0
        blurMax:64
    }

    //控制文字滚动
    Timer {
        id: rollingTimer
        interval: 100
        repeat: true
        running: false
        onTriggered: {
            var combinedNames = rollingLottery.guestNames.concat(rollingLottery.vipNames); // 合并两个数组
            var randomIndex = []
            // 提前确定需要生成的随机索引数量
            var nameCount = combinedNames.length;
            var limit = Math.min(rollingLottery.lotterySeatCount, nameCount);

            // 生成唯一随机索引
            while (randomIndex.length < limit) {
                var index = Math.floor(Math.random() * nameCount);
                if (!randomIndex.includes(index)) {
                    randomIndex.push(index);
                }
            }

            // 设置名字或占位符
            for (var i = 0; i < rollingLottery.lotterySeatCount; i++) {
                if (i < limit) {
                    lotterySeats.visibleChildren[i].text = combinedNames[randomIndex[i]];
                } else {
                    lotterySeats.visibleChildren[i].text = "- - -"; // 占位符
                }
            }
        }
    }

    //开始按钮
    Rectangle {
        id: startButton
        width: parent.width/3
        height: width/3
        radius: height/2
        border.width: height/20
        border.color:Qt.rgba(1.0, 0.8431, 0.0, 1.0) //金色
        anchors.horizontalCenter:parent.horizontalCenter
        anchors.bottom:parent.bottom
        anchors.bottomMargin: height
        property real gradientOffset: 0.02 // 颜色渐变偏移量
        property real flashSpeed: 0.12 // 文字闪烁速度
        property bool isRolling: rollingLottery.rolling // 是否在滚动中
        onIsRollingChanged: {
            if (isRolling) {
                flashSpeed *= 10.0; // 极速闪烁
            } else {
                flashSpeed /= 10.0; // 恢复闪烁速度
            }
            flashAnimation.restart()
        }

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: (0.0 + startButton.gradientOffset) % 1.0; color: "#FF0000" }  // 红
            GradientStop { position: (0.14 + startButton.gradientOffset) % 1.0; color: "#FF7F00" } // 橙
            GradientStop { position: (0.28 + startButton.gradientOffset) % 1.0; color: "#FFFF00" } // 黄
            GradientStop { position: (0.42 + startButton.gradientOffset) % 1.0; color: "#00FF00" } // 绿
            GradientStop { position: (0.56 + startButton.gradientOffset) % 1.0; color: "#0000FF" } // 蓝
            GradientStop { position: (0.70 + startButton.gradientOffset) % 1.0; color: "#4B0082" } // 靛
            GradientStop { position: (0.84 + startButton.gradientOffset) % 1.0; color: "#8B00FF" } // 紫
            GradientStop { position: (1.0 + startButton.gradientOffset) % 1.0; color: "#FF0000" }  // 红（循环）
        }

        // 动态控制渐变流动效果
        Timer {
            id: gradientTimer
            interval: 16
            repeat: true
            running: true
            onTriggered: {
                startButton.gradientOffset += startButton.isRolling ? 0.064 : 0.016; // 流动速度控制
                if (startButton.gradientOffset > 1.0) startButton.gradientOffset -= 1.0;
            }
        }

        //文字闪烁效果
        SequentialAnimation {
            id: flashAnimation
            loops: Animation.Infinite
            running: true
            PropertyAnimation {
                target: startButtonText
                property: "color"
                from: Qt.rgba(1, 1, 1, 1)
                to: Qt.rgba(0, 0, 0, 1)
                duration: 100 / startButton.flashSpeed
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: startButtonText
                property: "color"
                from: Qt.rgba(0, 0, 0, 1)
                to: Qt.rgba(1, 1, 1, 1)
                duration: 100 / startButton.flashSpeed
                easing.type: Easing.InOutQuad
            }
        }

        // 按钮文字
        Text {
            id: startButtonText
            text: startButton.isRolling ? "停止" : "开始"
            anchors.centerIn: parent
            font.pixelSize: parent.height/2
            font.bold: true
            color: "white"
        }

        // 按钮点击事件
        MouseArea {
            anchors.fill: parent
            onClicked: {
                rollingLottery.rolling = !rollingLottery.rolling
            }
        }
    }
    //开始按钮的金色阴影
    MultiEffect {
        source: startButton
        anchors.fill: startButton
        shadowEnabled: true
        shadowColor:Qt.rgba(1.0, 0.8431, 0.0, 1.0)
        blur:1.0
        blurMax:64
    }
}
