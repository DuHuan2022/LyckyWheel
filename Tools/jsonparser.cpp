#include "JsonParser.h"
#include <QJsonDocument>
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>

static const QString configFilePath = "config.json";
JsonParser::JsonParser(QObject *parent) : QObject(parent) {
    QFile file(configFilePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open config file:" << configFilePath;
        return;
    }
    _rawFileContent = file.readAll();
    file.close();
}

QString JsonParser::getWheelPrizesList() {
    QJsonDocument jsonDoc = QJsonDocument::fromJson(_rawFileContent);
    if (jsonDoc.isNull()) {
        return {};
    }

    QJsonObject jsonObj = jsonDoc.object();
    QJsonArray array = jsonObj["wheelPrizesList"].toArray();
    QJsonDocument doc(array);
    return doc.toJson();
}

QVariantList JsonParser::getGuestNames() {
    QJsonDocument jsonDoc = QJsonDocument::fromJson(_rawFileContent);
    if (jsonDoc.isNull()) {
        return {};
    }

    QJsonObject jsonObj = jsonDoc.object();
    return  jsonObj["guestNames"].toArray().toVariantList();
}

QVariantList JsonParser::getVipNames() {
    QJsonDocument jsonDoc = QJsonDocument::fromJson(_rawFileContent);
    if (jsonDoc.isNull()) {
        return {};
    }

    QJsonObject jsonObj = jsonDoc.object();
    return jsonObj["vipNames"].toArray().toVariantList();
}
