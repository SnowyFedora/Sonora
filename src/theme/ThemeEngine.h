#pragma once
#include <QColor>
#include <QObject>
#include <QUrl>
#include <QVariantAnimation>
#include <QVariantList>
#include <QVariantMap>

// Dynamic Color: seed -> тональные палитры (OKLCH) -> роли Material 3.
// Смена схемы анимируется здесь же (интерполяция по ролям), QML просто биндится.
class ThemeEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(QColor seedColor READ seedColor WRITE setSeedColor NOTIFY seedColorChanged)
    Q_PROPERTY(int mode READ mode WRITE setMode NOTIFY modeChanged) // 0 системная, 1 светлая, 2 тёмная
    Q_PROPERTY(bool dark READ isDark NOTIFY darkChanged)
    Q_PROPERTY(QVariantMap scheme READ scheme NOTIFY schemeChanged)
    Q_PROPERTY(QVariantList presetSeeds READ presetSeeds CONSTANT)

public:
    explicit ThemeEngine(QObject *parent = nullptr);

    QColor seedColor() const { return m_seed; }
    int mode() const { return m_mode; }
    bool isDark() const { return m_dark; }
    QVariantMap scheme() const { return m_current; }
    QVariantList presetSeeds() const;

    void setSeedColor(const QColor &c);
    void setMode(int mode);

    Q_INVOKABLE void useSystemAccent();
    Q_INVOKABLE bool seedFromImage(const QUrl &imageUrl);

signals:
    void seedColorChanged();
    void modeChanged();
    void darkChanged();
    void schemeChanged();

private:
    void refresh(bool animate);
    bool resolveDark() const;

    QColor m_seed;
    int m_mode = 0;
    bool m_dark = false;
    QVariantMap m_current;
    QVariantMap m_from;
    QVariantMap m_target;
    QVariantAnimation m_anim;
};
