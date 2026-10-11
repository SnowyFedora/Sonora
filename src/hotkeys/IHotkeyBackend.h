#pragma once
#include <QObject>
#include <QString>
#include <memory>

struct KeyCombo {
    Qt::KeyboardModifiers mods;
    int key = 0;          // Qt::Key
    bool keypad = false;  // клавиша с цифрового блока
};

// Платформенный бэкенд глобальных горячих клавиш.
class IHotkeyBackend : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;
    ~IHotkeyBackend() override = default;

    virtual QString name() const = 0;
    virtual bool registerHotkey(int id, const KeyCombo &combo) = 0;
    virtual void unregisterHotkey(int id) = 0;

signals:
    void activated(int id);
};

std::unique_ptr<IHotkeyBackend> createHotkeyBackend(QObject *parent);
