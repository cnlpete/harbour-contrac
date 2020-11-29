#ifndef EXPOSURENOTIFICATION_P_H
#define EXPOSURENOTIFICATION_P_H

#include <QObject>
#include <QTimer>
#include <QMutex>

#include "exposureinformation.h"
#include "contrac.h"
#include "metadata.h"
#include "exposurenotification.h"

namespace diagnosis {
class TemporaryExposureKeyExport;
} // namespace diagnosis

class ExposureNotificationPrivate : public QObject
{
    Q_OBJECT
public:
    explicit ExposureNotificationPrivate(ExposureNotification *q);
    ~ExposureNotificationPrivate();

    static bool loadDiagnosisKeys(QString const &keyFile, diagnosis::TemporaryExposureKeyExport * keyExport);

private:
    ExposureNotification *q_ptr;

    Q_DECLARE_PUBLIC(ExposureNotification)

public slots:
    void scanChanged();

signals:
    void terminating();

public:
    QMap<QString, QList<ExposureInformation>> m_exposures;
    ExposureNotification::Status m_status;
    Contrac *m_contrac;
    BleScanner *m_scanner;
    Controller *m_controller;
    ContactStorage *m_contacts;
    Metadata m_metadata;
    QTimer m_intervalUpdate;
    QMutex m_exposureMutex;
};

#endif // EXPOSURENOTIFICATION_P_H
