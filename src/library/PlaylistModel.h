#pragma once
#include "Playlist.h"

#include <QAbstractListModel>
#include <QHash>
#include <QTimer>

// Список плейлистов + CRUD. Хранится рядом с библиотекой в profiles/<name>/playlists.json
class PlaylistModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        NameRole,
        TrackCountRole,
        SoundIdsRole
    };

    explicit PlaylistModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_list.size(); }
    const Playlist *find(const QString &id) const;

    Q_INVOKABLE QString createPlaylist(const QString &name);
    Q_INVOKABLE void renamePlaylist(const QString &id, const QString &name);
    Q_INVOKABLE void removePlaylist(const QString &id);
    Q_INVOKABLE void addTrack(const QString &playlistId, const QString &soundId);
    Q_INVOKABLE void removeTrack(const QString &playlistId, const QString &soundId);
    Q_INVOKABLE void moveTrack(const QString &playlistId, int from, int to);
    Q_INVOKABLE QStringList tracksOf(const QString &playlistId) const;

    void load();
    void save();
    void setProfile(const QString &name);

signals:
    void countChanged();

private:
    void scheduleSave();
    QString storagePath() const;
    int indexOf(const QString &id) const;

    QList<Playlist> m_list;
    QHash<QString, int> m_index;
    QTimer m_saveTimer;
    QString m_profile = QStringLiteral("default");
};
