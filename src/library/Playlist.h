#pragma once
#include <QString>
#include <QStringList>

struct Playlist {
    QString id;
    QString name;
    QStringList soundIds; // порядок треков
};
