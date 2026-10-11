#include "SoundLibrary.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QStandardPaths>
#include <algorithm>
#include <QUuid>
#include <QVariantMap>

namespace {
bool isAudioSuffix(const QString &suffix)
{
    static const QSet<QString> exts{
        // lossless
        "wav", "flac", "aiff", "aif", "aifc", "caf", "wv", "ape", "alac",
        // lossy
        "mp3", "mp2", "ogg", "oga", "opus", "m4a", "m4b", "aac", "wma",
        "ac3", "eac3", "dts", "amr", "3ga",
        // контейнеры, которые часто содержат только аудио
        "mp4", "webm", "mkv"
    };
    return exts.contains(suffix.toLower());
}

QString makeId(const QString &path)
{
    return QString::fromLatin1(
        QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Sha1).toHex().left(12));
}
} // namespace

SoundLibrary::SoundLibrary(QObject *parent)
    : QAbstractListModel(parent)
{
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(600);
    connect(&m_saveTimer, &QTimer::timeout, this, &SoundLibrary::save);
}

int SoundLibrary::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_sounds.size();
}

QVariant SoundLibrary::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_sounds.size())
        return {};
    const Sound &s = m_sounds.at(index.row());
    switch (role) {
    case IdRole: return s.id;
    case TitleRole:
    case Qt::DisplayRole: return s.title;
    case PathRole: return s.path;
    case FolderRole: return s.folder;
    case TagsRole: return s.tags;
    case VolumeRole: return s.volume;
    case FavoriteRole: return s.favorite;
    case HotkeyRole: return s.hotkey;
    case LastPlayedRole: return s.lastPlayed;
    }
    return {};
}

QHash<int, QByteArray> SoundLibrary::roleNames() const
{
    return {
        {IdRole, "soundId"},     {TitleRole, "title"},       {PathRole, "path"},
        {FolderRole, "folder"},  {TagsRole, "tags"},         {VolumeRole, "volume"},
        {FavoriteRole, "favorite"}, {HotkeyRole, "hotkey"},  {LastPlayedRole, "lastPlayed"},
    };
}

QStringList SoundLibrary::folders() const
{
    QSet<QString> set;
    for (const Sound &s : m_sounds) {
        if (s.folder.isEmpty())
            continue;
        QString acc;
        for (const QString &part : s.folder.split('/')) {
            acc = acc.isEmpty() ? part : acc + '/' + part;
            set.insert(acc);
        }
    }
    QStringList list(set.begin(), set.end());
    list.sort(Qt::CaseInsensitive);
    return list;
}

const Sound *SoundLibrary::find(const QString &id) const
{
    const int row = m_index.value(id, -1);
    return row >= 0 ? &m_sounds.at(row) : nullptr;
}

int SoundLibrary::addFolder(const QUrl &folderUrl)
{
    const QString root = folderUrl.toLocalFile();
    QDir rootDir(root);
    if (root.isEmpty() || !rootDir.exists())
        return 0;

    const QString rootName = rootDir.dirName();
    QList<Sound> found;
    // TODO: вынести сканирование в QtConcurrent для больших коллекций
    QDirIterator it(root, QDir::Files, QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
    while (it.hasNext()) {
        it.next();
        const QFileInfo fi = it.fileInfo();
        if (!isAudioSuffix(fi.suffix()))
            continue;
        const QString id = makeId(fi.absoluteFilePath());
        if (m_index.contains(id))
            continue;
        const QString rel = rootDir.relativeFilePath(fi.absolutePath());
        Sound s;
        s.id = id;
        s.path = fi.absoluteFilePath();
        s.title = fi.completeBaseName();
        s.folder = (rel == QLatin1String(".")) ? rootName : rootName + '/' + rel;
        found.append(s);
    }
    std::sort(found.begin(), found.end(), [](const Sound &a, const Sound &b) {
        return QString::localeAwareCompare(a.title, b.title) < 0;
    });
    appendSounds(found);
    return found.size();
}

int SoundLibrary::addUrls(const QList<QUrl> &urls)
{
    int added = 0;
    QList<Sound> loose;
    for (const QUrl &url : urls) {
        if (!url.isLocalFile())
            continue;
        const QFileInfo fi(url.toLocalFile());
        if (fi.isDir()) {
            added += addFolder(url);
        } else if (isAudioSuffix(fi.suffix())) {
            const QString id = makeId(fi.absoluteFilePath());
            if (m_index.contains(id))
                continue;
            Sound s;
            s.id = id;
            s.path = fi.absoluteFilePath();
            s.title = fi.completeBaseName();
            s.folder = tr("Импорт");
            loose.append(s);
        }
    }
    appendSounds(loose);
    return added + loose.size();
}

void SoundLibrary::appendSounds(const QList<Sound> &sounds)
{
    if (sounds.isEmpty())
        return;
    const int first = m_sounds.size();
    beginInsertRows({}, first, first + sounds.size() - 1);
    m_sounds.append(sounds);
    endInsertRows();
    rebuildIndex();
    emit countChanged();
    emit foldersChanged();
    scheduleSave();
}

void SoundLibrary::rebuildIndex()
{
    m_index.clear();
    for (int i = 0; i < m_sounds.size(); ++i)
        m_index.insert(m_sounds.at(i).id, i);
}

template <typename Fn>
void SoundLibrary::update(const QString &id, int role, Fn &&fn)
{
    const int row = m_index.value(id, -1);
    if (row < 0)
        return;
    fn(m_sounds[row]);
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, {role});
    scheduleSave();
}

void SoundLibrary::setFavorite(const QString &id, bool favorite)
{
    update(id, FavoriteRole, [&](Sound &s) { s.favorite = favorite; });
}

void SoundLibrary::setVolume(const QString &id, qreal volume)
{
    update(id, VolumeRole, [&](Sound &s) { s.volume = qBound<qreal>(0.0, volume, 1.0); });
}

void SoundLibrary::setHotkey(const QString &id, const QString &sequence)
{
    update(id, HotkeyRole, [&](Sound &s) { s.hotkey = sequence; });
    emit hotkeysChanged();
}

void SoundLibrary::setTags(const QString &id, const QStringList &tags)
{
    update(id, TagsRole, [&](Sound &s) { s.tags = tags; });
}

void SoundLibrary::markPlayed(const QString &id)
{
    update(id, LastPlayedRole, [](Sound &s) { s.lastPlayed = QDateTime::currentMSecsSinceEpoch(); });
}

void SoundLibrary::setProfile(const QString &name)
{
    save();
    m_profile = name;
    load();
}

QString SoundLibrary::storagePath() const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                        + "/profiles/" + m_profile;
    QDir().mkpath(dir);
    return dir + "/library.json";
}

void SoundLibrary::scheduleSave()
{
    m_saveTimer.start();
}

void SoundLibrary::save()
{
    QJsonArray arr;
    for (const Sound &s : std::as_const(m_sounds)) {
        QJsonObject o;
        o["path"] = s.path;
        o["title"] = s.title;
        o["folder"] = s.folder;
        o["hotkey"] = s.hotkey;
        o["tags"] = QJsonArray::fromStringList(s.tags);
        o["volume"] = s.volume;
        o["favorite"] = s.favorite;
        o["lastPlayed"] = QString::number(s.lastPlayed);
        arr.append(o);
    }
    QJsonArray plArr;
    for (const Playlist &pl : std::as_const(m_playlists)) {
        QJsonObject o;
        o["id"] = pl.id;
        o["name"] = pl.name;
        o["tracks"] = QJsonArray::fromStringList(pl.trackIds);
        plArr.append(o);
    }
    QFile f(storagePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(QJsonObject{{"version", 2}, {"sounds", arr}, {"playlists", plArr}}).toJson(QJsonDocument::Compact));
}

void SoundLibrary::load()
{
    QList<Sound> loaded;
    QList<Playlist> loadedPl;
    QFile f(storagePath());
    if (f.open(QIODevice::ReadOnly)) {
        const auto doc = QJsonDocument::fromJson(f.readAll());
        const QJsonObject root = doc.object();
        for (const QJsonValue &v : root.value("sounds").toArray()) {
            const QJsonObject o = v.toObject();
            Sound s;
            s.path = o["path"].toString();
            if (s.path.isEmpty() || !QFileInfo::exists(s.path))
                continue;
            s.id = makeId(s.path);
            s.title = o["title"].toString();
            s.folder = o["folder"].toString();
            s.hotkey = o["hotkey"].toString();
            for (const QJsonValue &t : o["tags"].toArray())
                s.tags << t.toString();
            s.volume = o["volume"].toDouble(1.0);
            s.favorite = o["favorite"].toBool();
            s.lastPlayed = o["lastPlayed"].toString().toLongLong();
            loaded.append(s);
        }
        for (const QJsonValue &v : root.value("playlists").toArray()) {
            const QJsonObject o = v.toObject();
            Playlist pl;
            pl.id = o["id"].toString();
            pl.name = o["name"].toString();
            if (pl.id.isEmpty())
                pl.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
            for (const QJsonValue &t : o["tracks"].toArray())
                pl.trackIds << t.toString();
            loadedPl.append(pl);
        }
    }
    beginResetModel();
    m_sounds = loaded;
    m_playlists = loadedPl;
    rebuildIndex();
    endResetModel();
    emit countChanged();
    emit foldersChanged();
    emit hotkeysChanged();
    emit playlistsChanged();
}

QVariantList SoundLibrary::playlistsVariant() const
{
    QVariantList list;
    for (const Playlist &pl : m_playlists) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), pl.id);
        m.insert(QStringLiteral("name"), pl.name);
        m.insert(QStringLiteral("count"), pl.trackIds.size());
        list.append(m);
    }
    return list;
}

Playlist *SoundLibrary::findPlaylist(const QString &id)
{
    for (Playlist &pl : m_playlists)
        if (pl.id == id)
            return &pl;
    return nullptr;
}

const Playlist *SoundLibrary::findPlaylist(const QString &id) const
{
    for (const Playlist &pl : m_playlists)
        if (pl.id == id)
            return &pl;
    return nullptr;
}

QString SoundLibrary::createPlaylist(const QString &name)
{
    const QString n = name.trimmed().isEmpty() ? tr("Новый плейлист") : name.trimmed();
    Playlist pl;
    pl.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    pl.name = n;
    m_playlists.append(pl);
    emit playlistsChanged();
    scheduleSave();
    return pl.id;
}

void SoundLibrary::renamePlaylist(const QString &playlistId, const QString &name)
{
    if (Playlist *pl = findPlaylist(playlistId)) {
        pl->name = name.trimmed().isEmpty() ? pl->name : name.trimmed();
        emit playlistsChanged();
        scheduleSave();
    }
}

void SoundLibrary::deletePlaylist(const QString &playlistId)
{
    for (int i = 0; i < m_playlists.size(); ++i) {
        if (m_playlists.at(i).id == playlistId) {
            m_playlists.removeAt(i);
            emit playlistsChanged();
            scheduleSave();
            return;
        }
    }
}

void SoundLibrary::addToPlaylist(const QString &playlistId, const QString &soundId)
{
    Playlist *pl = findPlaylist(playlistId);
    if (!pl || !m_index.contains(soundId))
        return;
    if (pl->trackIds.contains(soundId))
        return;
    pl->trackIds.append(soundId);
    emit playlistsChanged();
    scheduleSave();
}

void SoundLibrary::removeFromPlaylist(const QString &playlistId, const QString &soundId)
{
    Playlist *pl = findPlaylist(playlistId);
    if (!pl)
        return;
    if (pl->trackIds.removeAll(soundId) > 0) {
        emit playlistsChanged();
        scheduleSave();
    }
}

bool SoundLibrary::isInPlaylist(const QString &playlistId, const QString &soundId) const
{
    const Playlist *pl = findPlaylist(playlistId);
    return pl && pl->trackIds.contains(soundId);
}

QStringList SoundLibrary::playlistTracks(const QString &playlistId) const
{
    const Playlist *pl = findPlaylist(playlistId);
    return pl ? pl->trackIds : QStringList{};
}

int SoundLibrary::playlistCount(const QString &playlistId) const
{
    const Playlist *pl = findPlaylist(playlistId);
    return pl ? pl->trackIds.size() : 0;
}
