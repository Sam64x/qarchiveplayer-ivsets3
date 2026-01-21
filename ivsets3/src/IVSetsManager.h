#pragma once

#include <QObject>

#include "IVSet.h"

class IVSetsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool freeEditEnabled READ freeEditEnabled WRITE setFreeEditEnabled NOTIFY freeEditEnabledChanged)
    Q_PROPERTY(int setsCount READ setsCount NOTIFY setsCountChanged)
    Q_PROPERTY(IVSet* activeSet READ activeSet NOTIFY activeSetChanged)

public:
    static IVSetsManager* instance();

    bool freeEditEnabled() const;
    void setFreeEditEnabled(bool enabled);

    int setsCount() const;

    IVSet* activeSet() const;
    Q_INVOKABLE void setActiveSet(IVSet* set);

    Q_INVOKABLE IVSet* getSet(const QString& setId) const;
    Q_INVOKABLE IVSet* createSet(const QVariant &jsonVariant);
    Q_INVOKABLE IVSet* createNewSet(const QString& setName);
    Q_INVOKABLE void clearSets();

    Q_INVOKABLE QString getSetConfigToSave(IVSet* set) const;

signals:
    void freeEditEnabledChanged();
    void activeSetChanged();
    void setsCountChanged();

private:
    IVSetsManager(QObject *parent = nullptr);

    bool _freeEditEnabled = false;
    IVSet* _activeSet = nullptr;
    QList<IVSet*> _sets;
};
