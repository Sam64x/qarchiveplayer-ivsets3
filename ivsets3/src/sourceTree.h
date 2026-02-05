#ifndef SOURCETREE_H
#define SOURCETREE_H

#include <QObject>
#include <QHash>

class SourceTree : public QObject
{
    Q_OBJECT

    // общие свойства, такие как имя, тип, тип отображения, видимость в списке
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString type READ type NOTIFY typeChanged)
    Q_PROPERTY(QString viewType READ viewType NOTIFY viewTypeChanged)
    Q_PROPERTY(bool visible READ visible NOTIFY visibleChanged)

    //уникальное свойство для viewType == "group"
    Q_PROPERTY(QList<QObject*> children READ childrenAsQObject NOTIFY childrenChanged)
    Q_PROPERTY(bool opened READ opened WRITE setOpened NOTIFY openedChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int unavailableCount READ unavailableCount NOTIFY unavailableCountChanged)
    Q_PROPERTY(QString groupColor READ groupColor NOTIFY groupColorChanged)

    //уникальное свойство для viewType == "item"
    Q_PROPERTY(bool selected READ selected NOTIFY selectedChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

    //уникальное свойство для type == "set"
    Q_PROPERTY(QString setId READ setId NOTIFY setIdChanged)
    Q_PROPERTY(bool isLocal READ isLocal NOTIFY isLocalChanged)

    //уникальное свойство для главного SourceTree
    Q_PROPERTY(int sourcesCount READ sourcesCount NOTIFY sourcesCountChanged)
    Q_PROPERTY(int selectedCamerasCount READ calculateSelectedCamerasCount NOTIFY selectedCamerasCountChanged)
    Q_PROPERTY(int selectedMapsCount READ calculateSelectedMapsCount NOTIFY selectedMapsCountChanged)

public:
    explicit SourceTree(QObject *parent = nullptr);

    QString name() const;
    void setName(const QString& name);

    QString type() const;
    void setType(const QString& type);

    QString viewType() const;
    void setViewType(const QString& value);

    bool visible() const;
    void setVisible(bool visible);

    QList<QObject*> childrenAsQObject() const;

    bool opened() const;
    void setOpened(bool opened);

    int count() const;
    void setCount(int value);

    int unavailableCount() const;
    void setUnavailableCount(int value);

    QString groupColor() const;
    void setGroupColor(const QString& value);

    bool selected() const;
    void setSelected(bool value);

    bool available() const;
    void setAvailable(bool value);

    QString setId() const;
    void setSetId(const QString& value);

    bool isLocal() const;
    void setIsLocal(bool isLocal);

    int sourcesCount() const;
    int calculateSelectedCamerasCount() const;
    int calculateSelectedMapsCount() const;
    Q_INVOKABLE void updateSelectedCameras(const QString& name, bool value);
    Q_INVOKABLE void updateSelectedMaps(const QString& name, bool value);
    Q_INVOKABLE void clearSelection();
    Q_INVOKABLE void changeCameraSelected(const QString& name, bool value);
    Q_INVOKABLE void changeMapSelected(const QString& name, bool value);
    Q_INVOKABLE void clearSourcesSelection();
    Q_INVOKABLE QStringList getSelectedCameras() const;

    Q_INVOKABLE void switchExpandAll(bool value);

    void clearChildren();
    void addChildItem(SourceTree*);

    Q_INVOKABLE void search(QString searchText);
    void showAll(SourceTree* root, bool openGroups = false);
    void filterNodeRecursively(SourceTree* item, QString searchText);

    Q_INVOKABLE void initSources();
    Q_INVOKABLE void initFlat();
    Q_INVOKABLE void initFact();
    Q_INVOKABLE void initCustom();

signals:
    void childrenChanged();
    void hasChildChanged();
    void nameChanged();
    void typeChanged();
    void viewTypeChanged();
    void openedChanged();
    void countChanged();
    void unavailableCountChanged();
    void visibleChanged();
    void isLocalChanged();
    void setIdChanged();
    void groupColorChanged();
    void selectedChanged();
    void availableChanged();
    void sourcesCountChanged();
    void selectedCamerasCountChanged();
    void selectedMapsCountChanged();

private:
    struct CustomGroupConfig {
        QString id;
        QString name;
        QString parentId;
        QString color;
    };

    SourceTree* createCameraItem(SourceTree* group, const QString& name) const;
    SourceTree* createMapItem(SourceTree* group, const QString& name) const;
    SourceTree* createSetItem(SourceTree* parent, const QJsonObject& setObject) const;
    SourceTree* createServerObject(QJsonObject serverObject, SourceTree* item);
    void createCustomGroupRecursed(SourceTree* parent,
                                   const QString& parentId,
                                   QList<CustomGroupConfig>& itemGroupsHash,
                                   QHash<QString, QList<QString>>& groupsSetsHash,
                                   QHash<QString, QJsonObject>& setsHash);

    QList<SourceTree *> _children;

    QString _name;
    QString _type;
    QString _viewType;
    bool _visible {true};
    bool _opened {false};
    int _count {0};
    int _unavailableCount {0};
    bool _isLocal {false};
    QString _setId;
    QString _groupColor;
    bool _selected {false};
    bool _available {false};

    struct ItemConfig {
        bool selected {false};
        bool available {false};
    };

    QHash<QString, ItemConfig> _camerasSources;
    QHash<QString, ItemConfig> _mapsSources;
};

#endif // SOURCETREE_H
