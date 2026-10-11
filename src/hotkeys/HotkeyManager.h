#pragma once
#include "IHotkeyBackend.h"

#include <QHash>
#include <QObject>

class HotkeyManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString backendName READ backendName CONSTANT)

public:
    explicit HotkeyManager(QObject *parent = nullptr);

    QString backendName() const { return m_backend->name(); }

    // Регистрирует сочетание для id. Пустая строка = снять.
    Q_INVOKABLE bool assign(const QString &id, const QString &sequence);
    Q_INVOKABLE void clear(const QString &id);
    Q_INVOKABLE void clearAll();
    // Какой id уже занимает это сочетание ("" если свободно)
    Q_INVOKABLE QString conflictFor(const QString &sequence, const QString &exceptId = {}) const;

    static bool parse(const QString &sequence, KeyCombo &out);

signals:
    void triggered(const QString &id);
    void registrationFailed(const QString &id, const QString &sequence);

private:
    std::unique_ptr<IHotkeyBackend> m_backend;
    QHash<QString, int> m_ids;           // id -> числовой id бэкенда
    QHash<int, QString> m_names;         // числовой id -> id
    QHash<QString, QString> m_sequences; // id -> нормализованное сочетание
    int m_nextId = 1;
};
