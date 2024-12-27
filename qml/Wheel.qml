import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Dialogs
import QtQuick.Controls.Basic

//转盘 (使用 Canvas 绘制多个分区)
Item { //根组件直接为Canvas的话无法被隐藏，不知道为啥
    property alias wheelPrizesList:wheel.wheelPrizesList
    property alias wheelColors:wheel.wheelColors
    property alias rotationAngle:wheel.rotationAngle
    property alias maxSpeed:wheel.maxSpeed
    property alias friction:wheel.friction
    property alias presetWinningSlice:wheel.presetWinningSlice
    property alias wheelVisible:wheel.visible
    property alias winningSlice:wheel.winningSlice
    property alias speedUpTime:wheel.speedUpTime
    function startSpinning(){
        wheel.startSpinning()
    }

    Canvas {
        id: wheel
        anchors.fill:parent
        property var wheelPrizesList:[  //stock是库存，每抽一次库存少1，库存为0的奖品置灰且永远不会抽到
            {"name": "奖品A", "stock": 1},
            {"name": "奖品B", "stock": 10},
            {"name": "奖品C", "stock": 4},
            {"name": "奖品D", "stock": 8},
            {"name": "奖品E", "stock": 0},
            {"name": "奖品F", "stock": 1},
            {"name": "奖品G", "stock": 7},
            {"name": "奖品H", "stock": 5},
            {"name": "奖品I", "stock": 4},
            {"name": "奖品J", "stock": 9},
            {"name": "奖品K", "stock": 3},
            {"name": "奖品L", "stock": 2},
            {"name": "奖品M", "stock": 12},
            {"name": "奖品N", "stock": 4},
            {"name": "奖品O", "stock": 6},
            {"name": "奖品P", "stock": 9}
        ]
        property var wheelColors: [
            "#E52D2D", // 红色
            "#E59C2D", // 橙色
            "#C0E52D", // 黄绿色
            "#52E52D", // 绿色
            "#2DE577", // 青绿色
            "#2DE5E5", // 青色
            "#2D77E5", // 蓝色
            "#522DE5", // 紫色
            "#C02DE5", // 粉紫色
            "#E52D9C"  // 品红色
        ]
        property int speedUpTime: 5000 //转盘的加速时间
        property real rotationAngle: Math.random()*360 // 当前转盘的旋转角度 (0~360)
        property real maxSpeed: 180 // 旋转的最大速度
        property real friction: 0.98 // 摩擦系数，控制减速
        property int presetWinningSlice: -1 //预设的中奖区域，值不合法时，或者选择的奖品库存为0，则中奖区域随机
        property int winningSlice: -1 // 当前的中奖分区，小于0时关闭闪烁

        //私有属性，外部不要更改
        property int diameter:Math.min(width, height) * 0.8  //转盘直径，不包含边框
        readonly property int numberOfSlices: wheelPrizesList.length // 分成几个部分
        property int lastWinningSlice: -1 // 上一次中奖的分区，用于在开始摇奖的时候更新奖品库存
        property bool isFlashing: false // 是否在闪烁状态
        property bool toggleState: false // 用于交替切换转盘边框红白点状态
        property real speed:0 // 当前旋转的速度 (每帧的旋转角度)
        property var wheelColorsInner:[]
        Component.onCompleted: {
            for(var i in wheelColors) {
                var color = wheelColors[i]
                color = color.startsWith("#") ? color.slice(1) : color;
                var r = parseInt(color.substring(0, 2), 16) / 255;
                var g = parseInt(color.substring(2, 4), 16) / 255;
                var b = parseInt(color.substring(4, 6), 16) / 255;
                var a = color.length === 8 ? parseInt(color.substring(6, 8), 16) / 255 : 1.0;
                wheelColorsInner[i] = Qt.rgba(r, g, b, a)
                // wheelColorsInner[i] = {
                //     startColor: Qt.rgba(
                //         Math.max(0.0, r - 0.3),
                //         Math.max(0.0, g - 0.3),
                //         Math.max(0.0, b - 0.3),
                //         a
                //     ),
                //     midLightColor: Qt.rgba(
                //         Math.max(0.0, r - 0.1),
                //         Math.max(0.0, g - 0.1),
                //         Math.max(0.0, b - 0.1),
                //         a
                //     ),
                //     midDarkColor: Qt.rgba(
                //         Math.min(1.0, r + 0.1),
                //         Math.min(1.0, g + 0.1),
                //         Math.min(1.0, b + 0.1),
                //         a
                //     ),
                //     endColor: Qt.rgba(
                //         Math.min(1.0, r + 0.3),
                //         Math.min(1.0, g + 0.3),
                //         Math.min(1.0, b + 0.3),
                //         a
                //     )
                // }
            }
        }

        //开启或关闭中奖区域闪烁效果，参数是要闪烁的区域，小于0时关闭闪烁
        onWinningSliceChanged: {
            if(winningSlice < 0) {
                flashTimer.stop()
                isFlashing = false
                return
            }
            flashTimer.start()
        }

        //开始旋转
        function startSpinning() {
            if(rotationTimer.running || visible === false) {
                return
            }
            //更新奖品库存
            if(lastWinningSlice >= 0 && lastWinningSlice < numberOfSlices) {
                var prize = wheelPrizesList[lastWinningSlice];
                if (prize.stock > 0) {
                    prize.stock--;
                }
            }
            //重置所有状态
            speedUpAnimation.stop()
            rotationTimer.stop()
            wheel.winningSlice = -1
            speed = 0
            lastWinningSlice = -1
            //检查是否有两种以上的有效奖品可以抽，如果都没库存了就终止
            var availablePrizes = 0
            for (var i in wheelPrizesList) {
                if (wheelPrizesList[i].stock > 0) {
                    availablePrizes++
                }
            }
            if(availablePrizes < 2) {
                messageDialog.text = "奖品都抽完啦！"
                messageDialog.open()
                return
            }
            //开始加速动画和timer
            speedUpAnimation.start()// 启动动画
            rotationTimer.start()
        }

        onPaint: {
            var ctx = getContext('2d');
            var centerX = width / 2;
            var centerY = height / 2;
            var radius = diameter / 2;

            // 清除画布，重新绘制
            ctx.clearRect(0, 0, diameter, diameter);

            var anglePerSlice = 360 / numberOfSlices; // 每个扇形的角度

            for (var i = 0; i < numberOfSlices; i++) {
                var startAngle = (anglePerSlice * i + rotationAngle) * Math.PI / 180;
                var endAngle = (anglePerSlice * (i + 1) + rotationAngle) * Math.PI / 180;

                ctx.beginPath();
                ctx.moveTo(centerX, centerY);
                ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                ctx.closePath();

                //判断此分区的颜色，判断逻辑：
                //如果库存为0则灰色
                //如果是中奖区域则通过isFlashing判断颜色
                //其余情况下是正常的颜色
                //开始填充颜色
                ctx.save();
                var prize = wheelPrizesList[i % numberOfSlices]
                if (prize.stock <= 0) {
                    //若库存为0置灰
                    ctx.fillStyle = Qt.rgba(0.5, 0.5, 0.5, 1)
                } else {
                    //其余情况正常
                    // var gradient = ctx.createRadialGradient(
                    //     centerX, centerY, radius / 4,
                    //     centerX, centerY, radius
                    // );

                    // // 使用 4 个颜色停靠点
                    // gradient.addColorStop(0, wheelColorsInner[i % wheelColorsInner.length].startColor);    // 深色边缘
                    // gradient.addColorStop(0.3, wheelColorsInner[i % wheelColorsInner.length].midLightColor); // 中间浅色
                    // gradient.addColorStop(0.6, wheelColorsInner[i % wheelColorsInner.length].midDarkColor); // 中间深色
                    // gradient.addColorStop(1, wheelColorsInner[i % wheelColorsInner.length].endColor);      // 浅色边缘
                    // ctx.fillStyle = gradient
                    ctx.fillStyle = wheelColorsInner[i % wheelColorsInner.length]
                    if(i === winningSlice && isFlashing){
                        //若为中奖区域则闪烁
                        //先涂一层正常颜色
                        ctx.fill();
                        //再混合白色以实现高亮效果
                        ctx.globalAlpha = 0.6; // 透明度，控制高亮效果
                        ctx.globalCompositeOperation = "lighter"; // 使用“亮度”混合模式
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 1); // 使用白色高亮
                    }
                }
                ctx.fill();
                ctx.restore();

                // 添加奖品文字和库存
                var textAngle = (startAngle + endAngle) / 2;
                ctx.save();
                ctx.translate(centerX, centerY);
                ctx.rotate(textAngle);
                ctx.textAlign = "right";
                ctx.fillStyle = Qt.rgba(0, 0, 0, 1);
                var fontSize = radius / 13;
                ctx.font = "bold " + fontSize + "px 微软雅黑";
                ctx.fillText(prize.name + " (" + prize.stock + ")", radius * 0.85, 10);
                ctx.restore();
            }

            // 绘制有质感的金色边框
            var borderWidth = diameter * 0.026; // 边框宽度

            // 创建渐变色
            var gradient = ctx.createRadialGradient(
                centerX, centerY, radius,
                centerX, centerY, radius + borderWidth
            );

            // 定义平滑渐变的金色层次
            gradient.addColorStop(0, Qt.rgba(1.0, 0.8431, 0.0, 1.0));      // 主金色 #FFD700
            gradient.addColorStop(0.4, Qt.rgba(1.0, 0.9725, 0.8627, 1.0)); // 浅金 #FFF8DC
            gradient.addColorStop(0.6, Qt.rgba(1.0, 0.7804, 0.0, 1.0));    // 深金 #FFC700
            gradient.addColorStop(1, Qt.rgba(0.8314, 0.6863, 0.2157, 1.0)); // 边缘深金 #D4AF37

            // 绘制边框
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius + borderWidth / 2, 0, 2 * Math.PI);
            ctx.lineWidth = borderWidth;
            ctx.strokeStyle = gradient; // 使用渐变作为边框样式
            ctx.stroke();
            ctx.closePath();

            // 绘制边框上的点（红点和白点交替）
            var dotRadius = borderWidth * 0.4; // 点的半径
            var dotCount = 36; // 点的数量
            var anglePerDot = 360 / dotCount;
            for (var d = 0; d < dotCount; d++) {
                var dotAngle = (anglePerDot * d) * Math.PI / 180;
                var dotX = centerX + (radius + borderWidth/2) * Math.cos(dotAngle);
                var dotY = centerY + (radius + borderWidth/2) * Math.sin(dotAngle);

                ctx.beginPath();
                ctx.arc(dotX, dotY, dotRadius, 0, 2 * Math.PI);
                // 闪烁：根据 toggleState 和索引控制颜色
                if ((d % 2 === 0 && toggleState) || (d % 2 !== 0 && !toggleState)) {
                    ctx.fillStyle = Qt.rgba(1, 1, 1, 1)
                } else {
                    ctx.fillStyle = Qt.rgba(1, 0, 0, 1);
                }
                ctx.fill();
                ctx.closePath();
            }
        }
        // 定时器控制中奖区域的闪烁
        Timer {
            id: flashTimer
            interval: 200 // 每200ms 闪烁一次
            repeat: true
            onTriggered: {
                wheel.isFlashing = !wheel.isFlashing; // 反转状态
                wheel.requestPaint();
            }
        }

        //用于转盘边框红白点的闪烁
        Timer {
            interval: 800
            running: true
            repeat: true
            onTriggered: {
                wheel.toggleState = !wheel.toggleState; // 切换状态
                wheel.requestPaint();
            }
        }

        // 定时器控制旋转
        Timer {
            id: rotationTimer
            interval: 16 // 16ms 每帧，大约 60FPS
            running: false
            repeat: true
            onTriggered: {
                if(!speedUpAnimation.running) {
                    //加速动画运行完了就开始减速
                    wheel.speed *= wheel.friction;
                }
                wheel.rotationAngle += wheel.speed;
                wheel.rotationAngle %= 360;
                if (wheel.speed < 0.1) {
                    rotationTimer.stop();
                    wheel.speed = 0;

                    // 计算中奖的分区
                    var finalAngle = wheel.rotationAngle % 360;
                    var winningSlice = Math.floor((360 - finalAngle) / (360 / wheel.numberOfSlices)) % wheel.numberOfSlices;

                    wheel.lastWinningSlice = winningSlice

                    // 启动闪烁定时器
                    wheel.winningSlice = winningSlice
                }
                wheel.requestPaint();
            }
        }

        //转盘加速动画
          NumberAnimation  {
              id:speedUpAnimation
              target: wheel
              property: "speed"
              from: 0
              to: wheel.maxSpeed
              duration: wheel.speedUpTime
              easing.type: Easing.OutExpo
              onFinished : {
                  //在加速阶段结束后，这里控制转盘最终的落点
                  //先计算速度从最大减少到0总共需要偏转多少度
                  var speed = wheel.maxSpeed
                  var sum = 0
                  while (speed >= 0.1) {
                      speed *= wheel.friction
                      sum += speed
                  }
                  var currentFinal = ((sum % 360) + 360) % 360
                  var winningOffset
                  if(wheel.presetWinningSlice < 0
                          ||wheel.presetWinningSlice >= wheel.numberOfSlices
                          ||wheel.wheelPrizesList[wheel.presetWinningSlice].stock <= 0) {
                      //预设中奖区域大于奖品数量，或者预设中奖区域小于0，或者预设的奖品库存为0时随机
                      winningOffset = Math.random()*360
                  } else {
                      //计算出预设奖品的偏转角度
                      var reversedIndex = wheel.numberOfSlices - 1 - wheel.presetWinningSlice
                      var desiredAngle = (reversedIndex + 0.5) * (360 / wheel.numberOfSlices)
                      var offset = desiredAngle - currentFinal
                      winningOffset = (offset + 360) % 360
                      //此时的角度是奖品区域的正中央，所以再偏转一点点随机角度，更加拟真
                      winningOffset += (Math.random() - 0.5) * 360 / wheel.numberOfSlices
                  }
                  wheel.rotationAngle = winningOffset
                  //检查是不是转到了库存为0的区域，如果是的话就再加上一个扇区的角度
                  var finalAngle = (wheel.rotationAngle + currentFinal) % 360;
                  var winningSlice = Math.floor((360 - finalAngle) / (360 / wheel.numberOfSlices)) % wheel.numberOfSlices
                  while(winningSlice < wheel.numberOfSlices && wheel.wheelPrizesList[winningSlice].stock <= 0) {
                      wheel.rotationAngle -= 360 / wheel.numberOfSlices
                      wheel.rotationAngle = (wheel.rotationAngle + 360) % 360
                      winningSlice++
                  }
              }
          }

        // 右侧的倒三角指针
        Canvas {
            id: pointer
            width: wheel.diameter*0.1
            height: wheel.diameter*0.06
            anchors.centerIn : wheel
            anchors.horizontalCenterOffset:wheel.diameter/2
            onPaint: {
                var ctx = getContext('2d');
                ctx.clearRect(0, 0, width, height);

                // 开启抗锯齿
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.translate(0.5, 0.5);

                ctx.beginPath();
                ctx.moveTo(0, height / 2);
                ctx.lineTo(width, 0);
                ctx.lineTo(width, height);
                ctx.closePath();

                ctx.fillStyle = Qt.rgba(0.53, 0.81, 0.98, 1)
                ctx.fill();
            }
        }
        //指针阴影效果
        MultiEffect {
            source: pointer
            anchors.fill: pointer
            shadowEnabled: true
        }

        //开始按钮
        Button {
            id:startButton
            width: wheel.diameter*0.08
            height: width
            anchors.centerIn: wheel
            hoverEnabled:false
            background: Rectangle {
                radius: width/2
                color: 'white'
            }
            onClicked:{
                wheel.startSpinning()
            }
        }
        //开始按钮阴影效果
        MultiEffect {
            source: startButton
            anchors.fill: startButton
            shadowEnabled: true
        }

        // 消息对话框
        MessageDialog {
            id: messageDialog
            title: "提示"
            text: ""
        }
    }
}
