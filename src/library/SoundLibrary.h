#pragma once
#include "Sound.h"

#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QTimer>
#include <QUrl>
#include <QVariantList>

struct Playlist {
    QString id;
    QString name;
    QStringList trackIds;
};

class SoundLibrary : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QStringList folders READ folders NOTIFY foldersChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QVariantList playlists READ playlistsVariant NOTIFY playlistsChanged)

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        PathRole,
        FolderRole,
        TagsRole,
        VolumeRole,
        FavoriteRole,
        HotkeyRole,
        LastPlayedRole
    };

    explicit SoundLibrary(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_sounds.size(); }
    QStringList folders() const;
    const Sound *find(const QString &id) const;
    const QList<Sound> &all() const { return m_sounds; }
    const QList<Playlist> &playlists() const { return m_playlists; }
    QVariantList playlistsVariant() const;

    Q_INVOKABLE int addFolder(const QUrl &folderUrl);
    Q_INVOKABLE int addUrls(const QList<QUrl> &urls);
    Q_INVOKABLE void setFavorite(const QString &id, bool favorite);
    Q_INVOKABLE void setVolume(const QString &id, qreal volume);
    Q_INVOKABLE void setHotkey(const QString &id, const QString &sequence);
    Q_INVOKABLE void setTags(const QString &id, const QStringList &tags);
    void markPlayed(const QString &id);

    // Плейлисты
    Q_INVOKABLE QString createPlaylist(const QString &name);
    Q_INVOKABLE void renamePlaylist(const QString &playlistId, const QString &name);
    Q_INVOKABLE void deletePlaylist(const QString &playlistId);
    Q_INVOKABLE void addToPlaylist(const QString &playlistId, const QString &soundId);
    Q_INVOKABLE void removeFromPlaylist(const QString &playlistId, const QString &soundId);
    Q_INVOKABLE bool isInPlaylist(const QString &playlistId, const QString &soundId) const;
    Q_INVOKABLE QStringList playlistTracks(const QString &playlistId) const;
    Q_INVOKABLE int playlistCount(const QString &playlistId) const;

    void load();
    void save();
    void setProfile(const QString &name);

signals:
    void foldersChanged();
    void countChanged();
    void hotkeysChanged();
    void playlistsChanged();

private:
    template <typename Fn>
    void update(const QString &id, int role, Fn &&fn);
    void appendSounds(const QList<Sound> &sounds);
    void rebuildIndex();
    void scheduleSave();
    QString storagePath() const;
    Playlist *findPlaylist(const QString &id);
    const Playlist *findPlaylist(const QString &id) const;

    QList<Sound> m_sounds;
    QHash<QString, int> m_index;
    QList<Playlist> m_playlists;
    QTimer m_saveTimer;
    QString m_profile = QStringLiteral("default");
};
