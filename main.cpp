#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <jsonparser.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("LuckyWheel", "MainWindow");
    // for(QString path : engine.importPathList())
    //     qDebug() << path;
    //engine.load(QUrl(QStringLiteral("MainWindow.qml")));

    return app.exec();
}
