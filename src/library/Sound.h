#pragma once
#include <QString>
#include <QStringList>
#include <QtGlobal>

struct Sound {
    QString id;          // стабильный хэш пути
    QString path;        // абсолютный путь к файлу
    QString title;
    QString folder;      // "Корень/Подпапка/Ещё"
    QString hotkey;      // "Ctrl+Alt+1" (PortableText)
    QStringList tags;
    qreal volume = 1.0;  // индивидуальная громкость 0..1
    bool favorite = false;
    qint64 lastPlayed = 0; // ms since epoch, 0 = никогда
};
