#ifndef JSONPARSER_H
#define JSONPARSER_H

#include <QObject>
#include <QVariant>
#include <qqml.h>

class JsonParser : public QObject {
    Q_OBJECT
    QML_ELEMENT
public:
    explicit JsonParser(QObject *parent = nullptr);

    Q_INVOKABLE QString getWheelPrizesList();
    Q_INVOKABLE QVariantList getGuestNames();
    Q_INVOKABLE QVariantList getVipNames();

private:
    QByteArray _rawFileContent;
};

#endif // JSONPARSER_H
