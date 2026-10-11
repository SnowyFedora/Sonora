#pragma once
#include <QSortFilterProxyModel>
#include <QStringList>
#include <QtGlobal>

class SoundFilterModel : public QSortFilterProxyModel {
    Q_OBJECT
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(QString folder READ folder WRITE setFolder NOTIFY folderChanged)
    Q_PROPERTY(bool onlyFavorites READ onlyFavorites WRITE setOnlyFavorites NOTIFY onlyFavoritesChanged)
    Q_PROPERTY(bool recentOnly READ recentOnly WRITE setRecentOnly NOTIFY recentOnlyChanged)
    Q_PROPERTY(QString playlistId READ playlistId WRITE setPlaylistId NOTIFY playlistIdChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit SoundFilterModel(QObject *parent = nullptr);

    QString searchText() const { return m_search; }
    QString folder() const { return m_folder; }
    bool onlyFavorites() const { return m_favorites; }
    bool recentOnly() const { return m_recent; }
    QString playlistId() const { return m_playlistId; }
    int count() const { return rowCount(); }

    void setSearchText(const QString &v);
    void setFolder(const QString &v);
    void setOnlyFavorites(bool v);
    void setRecentOnly(bool v);
    void setPlaylistId(const QString &v);

signals:
    void searchTextChanged();
    void folderChanged();
    void onlyFavoritesChanged();
    void recentOnlyChanged();
    void playlistIdChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;
    bool lessThan(const QModelIndex &l, const QModelIndex &r) const override;

private:
    template <typename Fn>
    void changeFilter(Fn &&fn)
    {
#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)
        beginFilterChange();
        fn();
        endFilterChange();
#else
        fn();
        invalidateFilter();
#endif
    }

    QString m_search;
    QString m_folder;
    QString m_playlistId;
    QStringList m_playlistTracks;
    bool m_favorites = false;
    bool m_recent = false;
};
