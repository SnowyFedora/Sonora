#include "SoundFilterModel.h"
#include "SoundLibrary.h"

SoundFilterModel::SoundFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    sort(0);
    auto notify = [this] { emit countChanged(); };
    connect(this, &QAbstractItemModel::rowsInserted, this, notify);
    connect(this, &QAbstractItemModel::rowsRemoved, this, notify);
    connect(this, &QAbstractItemModel::modelReset, this, notify);
    connect(this, &QAbstractItemModel::layoutChanged, this, notify);
}

void SoundFilterModel::setSearchText(const QString &v)
{
    if (m_search == v)
        return;
    changeFilter([&] { m_search = v; });
    emit searchTextChanged();
    emit countChanged();
}

void SoundFilterModel::setFolder(const QString &v)
{
    if (m_folder == v)
        return;
    changeFilter([&] { m_folder = v; });
    emit folderChanged();
    emit countChanged();
}

void SoundFilterModel::setOnlyFavorites(bool v)
{
    if (m_favorites == v)
        return;
    changeFilter([&] { m_favorites = v; });
    emit onlyFavoritesChanged();
    emit countChanged();
}

void SoundFilterModel::setRecentOnly(bool v)
{
    if (m_recent == v)
        return;
    m_recent = v;
    invalidate();
    emit recentOnlyChanged();
    emit countChanged();
}

void SoundFilterModel::setPlaylistId(const QString &v)
{
    if (m_playlistId == v)
        return;
    m_playlistId = v;
    m_playlistTracks.clear();
    if (auto *lib = qobject_cast<SoundLibrary *>(sourceModel()))
        m_playlistTracks = lib->playlistTracks(v);
    changeFilter([&] {});
    emit playlistIdChanged();
    emit countChanged();
}

bool SoundFilterModel::filterAcceptsRow(int row, const QModelIndex &parent) const
{
    const QAbstractItemModel *src = sourceModel();
    if (!src)
        return false;
    const QModelIndex idx = src->index(row, 0, parent);

    if (m_favorites && !src->data(idx, SoundLibrary::FavoriteRole).toBool())
        return false;
    if (m_recent && src->data(idx, SoundLibrary::LastPlayedRole).toLongLong() <= 0)
        return false;

    if (!m_playlistId.isEmpty()) {
        const QString id = src->data(idx, SoundLibrary::IdRole).toString();
        if (!m_playlistTracks.contains(id))
            return false;
    }

    const QString folder = src->data(idx, SoundLibrary::FolderRole).toString();
    if (!m_folder.isEmpty() && folder != m_folder && !folder.startsWith(m_folder + '/'))
        return false;

    if (!m_search.isEmpty()) {
        const QString title = src->data(idx, SoundLibrary::TitleRole).toString();
        const QStringList tags = src->data(idx, SoundLibrary::TagsRole).toStringList();
        const Qt::CaseSensitivity cs = Qt::CaseInsensitive;
        bool hit = title.contains(m_search, cs) || folder.contains(m_search, cs);
        for (const QString &t : tags)
            hit = hit || t.contains(m_search, cs);
        if (!hit)
            return false;
    }
    return true;
}

bool SoundFilterModel::lessThan(const QModelIndex &l, const QModelIndex &r) const
{
    if (m_recent) {
        return l.data(SoundLibrary::LastPlayedRole).toLongLong()
               > r.data(SoundLibrary::LastPlayedRole).toLongLong();
    }
    // В плейлисте — порядок как в trackIds
    if (!m_playlistId.isEmpty() && !m_playlistTracks.isEmpty()) {
        const int li = m_playlistTracks.indexOf(l.data(SoundLibrary::IdRole).toString());
        const int ri = m_playlistTracks.indexOf(r.data(SoundLibrary::IdRole).toString());
        return li < ri;
    }
    return QString::localeAwareCompare(l.data(SoundLibrary::TitleRole).toString(),
                                       r.data(SoundLibrary::TitleRole).toString()) < 0;
}
