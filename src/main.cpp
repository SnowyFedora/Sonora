#include "app/AppController.h"
#include "library/SoundFilterModel.h"

#include <QApplication>
#include <QDir>
#include <QFileInfo>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtQml>
#include <QDebug>
#include <QTimer>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setOrganizationName("Sonora");
    app.setApplicationName("Sonora");
    app.setApplicationVersion("0.1.0");

    QQuickStyle::setStyle("Basic");

    AppController controller;
    qmlRegisterSingletonInstance("Sonora.Core", 1, 0, "App", &controller);
    qmlRegisterType<SoundFilterModel>("Sonora.Core", 1, 0, "SoundFilterModel");

    QQmlApplicationEngine engine;

    const QString appDir = QCoreApplication::applicationDirPath();
    engine.addImportPath(appDir);
    engine.addImportPath(appDir + QStringLiteral("/qml"));
    engine.addImportPath(appDir + QStringLiteral("/../share/sonora/qml"));
    engine.addImportPath(appDir + QStringLiteral("/../lib/qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule("Sonora", "Main");

    if (engine.rootObjects().isEmpty()) {
        qCritical("Sonora: не удалось загрузить QML (модуль Sonora/Main). "
                  "Проверьте установку: share/sonora/qml рядом с бинарником.");
        return 1;
    }

    // Аргументы: sonora file1.mp3 file2.flac ... (от «Открыть с помощью» / %F)
    QStringList toOpen;
    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        const QString &a = args.at(i);
        if (a.startsWith(QLatin1Char('-')))
            continue; // флаги Qt / наши
        toOpen.append(a);
    }
    if (!toOpen.isEmpty()) {
        // После загрузки QML, чтобы тосты/UI уже были
        QTimer::singleShot(0, &controller, [&controller, toOpen] {
            controller.openPaths(toOpen);
        });
    }

    return app.exec();
}
