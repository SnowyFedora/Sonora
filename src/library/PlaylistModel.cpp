#include "PlaylistModel.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUuid>

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &PlaylistModel::save);
}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_list.size();
}

QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_list.size())
        return {};
    const Playlist &p = m_list.at(index.row());
    switch (role) {
    case IdRole: return p.id;
    case NameRole:
    case Qt::DisplayRole: return p.name;
    case TrackCountRole: return p.soundIds.size();
    case SoundIdsRole: return p.soundIds;
    }
    return {};
}

QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    return {
        {IdRole, "playlistId"},
        {NameRole, "name"},
        {TrackCountRole, "trackCount"},
        {SoundIdsRole, "soundIds"},
    };
}

const Playlist *PlaylistModel::find(const QString &id) const
{
    const int i = indexOf(id);
    return i >= 0 ? &m_list.at(i) : nullptr;
}

int PlaylistModel::indexOf(const QString &id) const
{
    return m_index.value(id, -1);
}

QString PlaylistModel::createPlaylist(const QString &name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
        return {};

    Playlist p;
    p.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    p.name = trimmed;

    const int row = m_list.size();
    beginInsertRows({}, row, row);
    m_list.append(p);
    m_index.insert(p.id, row);
    endInsertRows();
    emit countChanged();
    scheduleSave();
    return p.id;
}

void PlaylistModel::renamePlaylist(const QString &id, const QString &name)
{
    const int i = indexOf(id);
    if (i < 0)
        return;
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty() || trimmed == m_list[i].name)
        return;
    m_list[i].name = trimmed;
    const QModelIndex idx = index(i);
    emit dataChanged(idx, idx, {NameRole});
    scheduleSave();
}

void PlaylistModel::removePlaylist(const QString &id)
{
    const int i = indexOf(id);
    if (i < 0)
        return;
    beginRemoveRows({}, i, i);
    m_list.removeAt(i);
    endRemoveRows();
    // пересобрать индекс
    m_index.clear();
    for (int r = 0; r < m_list.size(); ++r)
        m_index.insert(m_list.at(r).id, r);
    emit countChanged();
    scheduleSave();
}

void PlaylistModel::addTrack(const QString &playlistId, const QString &soundId)
{
    const int i = indexOf(playlistId);
    if (i < 0 || soundId.isEmpty())
        return;
    if (m_list[i].soundIds.contains(soundId))
        return; // без дублей
    m_list[i].soundIds.append(soundId);
    const QModelIndex idx = index(i);
    emit dataChanged(idx, idx, {TrackCountRole, SoundIdsRole});
    scheduleSave();
}

void PlaylistModel::removeTrack(const QString &playlistId, const QString &soundId)
{
    const int i = indexOf(playlistId);
    if (i < 0)
        return;
    if (!m_list[i].soundIds.removeOne(soundId))
        return;
    const QModelIndex idx = index(i);
    emit dataChanged(idx, idx, {TrackCountRole, SoundIdsRole});
    scheduleSave();
}

void PlaylistModel::moveTrack(const QString &playlistId, int from, int to)
{
    const int i = indexOf(playlistId);
    if (i < 0)
        return;
    auto &ids = m_list[i].soundIds;
    if (from < 0 || from >= ids.size() || to < 0 || to >= ids.size() || from == to)
        return;
    ids.move(from, to);
    const QModelIndex idx = index(i);
    emit dataChanged(idx, idx, {SoundIdsRole});
    scheduleSave();
}

QStringList PlaylistModel::tracksOf(const QString &playlistId) const
{
    if (const Playlist *p = find(playlistId))
        return p->soundIds;
    return {};
}

void PlaylistModel::setProfile(const QString &name)
{
    save();
    m_profile = name;
    load();
}

QString PlaylistModel::storagePath() const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                        + "/profiles/" + m_profile;
    QDir().mkpath(dir);
    return dir + "/playlists.json";
}

void PlaylistModel::scheduleSave()
{
    m_saveTimer.start();
}

void PlaylistModel::save()
{
    QJsonArray arr;
    for (const Playlist &p : std::as_const(m_list)) {
        QJsonObject o;
        o["id"] = p.id;
        o["name"] = p.name;
        o["tracks"] = QJsonArray::fromStringList(p.soundIds);
        arr.append(o);
    }
    QFile f(storagePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(QJsonObject{{"version", 1}, {"playlists", arr}}).toJson(QJsonDocument::Compact));
}

void PlaylistModel::load()
{
    QList<Playlist> loaded;
    QFile f(storagePath());
    if (f.open(QIODevice::ReadOnly)) {
        const auto doc = QJsonDocument::fromJson(f.readAll());
        for (const QJsonValue &v : doc.object().value("playlists").toArray()) {
            const QJsonObject o = v.toObject();
            Playlist p;
            p.id = o["id"].toString();
            p.name = o["name"].toString();
            if (p.id.isEmpty() || p.name.isEmpty())
                continue;
            for (const QJsonValue &t : o["tracks"].toArray())
                p.soundIds << t.toString();
            loaded.append(p);
        }
    }
    beginResetModel();
    m_list = loaded;
    m_index.clear();
    for (int r = 0; r < m_list.size(); ++r)
        m_index.insert(m_list.at(r).id, r);
    endResetModel();
    emit countChanged();
}
