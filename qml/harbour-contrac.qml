import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.time 1.0
import uk.co.flypig.contrac 1.0
import Nemo.DBus 2.0
import "pages"

ApplicationWindow
{
    id: root
    readonly property bool downloadAvailable: moreThanADayAgo(AppSettings.summaryUpdated)
    property bool updating
    readonly property bool busy: upload.uploading || download.downloading || updating || dbusproxy.isBusy
    readonly property string token: "abcdef"

    DBusProxy {
        id: dbusproxy
    }

    Upload {
        id: upload
    }

    Download {
        id: download
        onDownloadingChanged: {
            if (!downloading) {
                autoUpdate.updateComplete();
            }
        }
    }

    WallClock {
        id: wallclock
        updateFrequency: WallClock.Day
    }

    RiskStatus {
        id: riskStatus
    }

    AutoUpdate {
        id: autoUpdate
        onStartUpdate: {
            download.downloadLatest()
        }
    }

    AppStatus {
        id: appStatus

        statusOfDownload: download.status
        statusOfUpload: upload.status
        updating: root.updating
        bluetoothBusy: dbusproxy.isBusy
        bluetoothEnabled: dbusproxy.isEnabled
        atRisk: riskStatus.riskClassIndex > 0
        downloadAvailable: root.downloadAvailable

        onNotifyAtRisk: Notifications.notifyAtRisk(riskStatus.riskClassLabel)
        onNotifyUpdateSuccessful: Notifications.notifyUpdateSuccessful()
        onNotifyDownloadError: Notifications.notifyDownloadError()
        onNotifyUploadError: Notifications.notifyUploadError()
    }

    function updateSummary() {
        console.log("Exposure summary")
        var summary = dbusproxy.getExposureSummary(token)
        console.log("Attenuation durations: " + summary.attenuationDurations)
        console.log("Days since last exposure: " + summary.daysSinceLastExposure)
        console.log("Matched key count: " + summary.matchedKeyCount)
        console.log("Maximum risk score: " + summary.maximumRiskScore)
        console.log("Summation risk score: " + summary.summationRiskScore)
        AppSettings.summaryUpdated = dbusproxy.lastProcessTime(token)
        AppSettings.latestSummary = summary
    }

    Component.onCompleted: {
        var exposureState = dbusproxy.exposureState(token)
        updating = (exposureState === DBusProxy.Processing)
        if (exposureState === DBusProxy.Available) {
            if (dbusproxy.lastProcessTime(token) > AppSettings.summaryUpdated) {
                // Summary data was processed while the app was closed
                updateSummary()
            }
        }
    }

    Connections {
        target: dbusproxy

        onExposureStateChanged: {
            if (token === root.token) {
                updating = (dbusproxy.exposureState(token) === DBusProxy.Processing)
            }
        }

        onActionExposureStateUpdated: {
            if (token === root.token) {
                // Summary data has been processed
                updateSummary()
            }
        }
    }

    function moreThanADayAgo(latest) {
        var result = true
        if (!isNaN(latest)) {
            var today = wallclock.time
            today.setSeconds(0)
            today.setMinutes(0)
            today.setHours(0)
            today.setMilliseconds(0)
            latest.setSeconds(0)
            latest.setMinutes(0)
            latest.setHours(0)
            latest.setMilliseconds(0)
            result = ((today - latest) >= (24 * 60 * 60 * 1000))
        }
        return result
    }

    function triggerEnabled() {
        if (!dbusproxy.isBusy) {
            if (dbusproxy.isEnabled) {
                console.log("Clicked to stop")
                dbusproxy.stop();
            }
            else {
                console.log("Clicked to start")
                dbusproxy.start();
            }
        }
        else {
            console.log("Can't start or stop while busy")
        }
    }

    initialPage: Component { Main { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
}
