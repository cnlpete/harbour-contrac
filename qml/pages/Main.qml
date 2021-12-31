import QtQuick 2.0
import Sailfish.Silica 1.0
import uk.co.flypig.contrac 1.0

Page {
    id: page
    property bool updatePending

    allowedOrientations: Orientation.All

    function performUpdate() {
        updatePending = false
        var filelist = download.fileList()
        console.log("Files to check: " + filelist.length)

        dbusproxy.provideDiagnosisKeys(filelist, download.config, token)
    }

    Connections {
        target: upload

        onTestResultRetrieved: {
            testResult.testResultDownloaded(result)
        }
        onRegTokenStored: {
            testResult.regTokenWasReceived()
        }
        onDiagnosisKeysSubmittedSuccessfully: {
            testResult.startCheck()
        }
    }

    Connections {
        target: download

        onAllFilesDownloaded: {
            // The download just finished
            if (page.status === PageStatus.Active) {
                performUpdate()
            }
            else {
                updatePending = true
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (AppSettings.infoViewed === 0) {
                pageStack.push(Qt.resolvedUrl("Info.qml"));
                AppSettings.infoViewed = 1;
            }
            if (updatePending) {
                performUpdate()
            }
        }
    }

    Connections {
        target: testResult

        onTestResultRequested: {
            if (!upload.uploading) {
                upload.checkForTestResult(regToken)
            }
        }
    }

    Component.onCompleted: testResult.startCheck()

    SilicaListView {
        anchors.fill: parent
        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                //% "About"
                text: qsTrId("contrac-main_about")
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }
            MenuItem {
                //% "Settings"
                text: qsTrId("contrac-main_settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
        }

        header: Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //% "Contrac Exposure Notification"
                title: qsTrId("contrac-main_title")
            }

            SectionHeader {
                //% "Status"
                text: qsTrId("contrac-main_he_status")
            }

            Item {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Theme.itemSizeSmall

                BusyIndicator {
                    id: progress
                    anchors.verticalCenter: parent.verticalCenter
                    running: visible
                    size: BusyIndicatorSize.Small
                    visible: busy
                }

                Image {
                    anchors.fill: progress
                    visible: !progress.visible
                    source: {
                        if (upload.status === Upload.StatusError) {
                            return Qt.resolvedUrl("image://contrac/icon-s-warning")
                        } else if (upload.status === Upload.StatusError) {
                            return Qt.resolvedUrl("image://contrac/icon-s-warning")
                        } else if (download.status === Download.StatusError) {
                            return Qt.resolvedUrl("image://contrac/icon-s-warning")
                        } else if (AppSettings.latestSummary.summationRiskScore >= 15) {
                            return Qt.resolvedUrl("image://contrac/icon-s-warning")
                        } else if (downloadAvailable) {
                            return Qt.resolvedUrl("image://contrac/icon-s-unknown")
                        } else if (!dbusproxy.isEnabled) {
                            return Qt.resolvedUrl("image://contrac/icon-s-inactive")
                        } else {
                            return Qt.resolvedUrl("image://contrac/icon-s-active")
                        }
                    }
                }

                Label {
                    id: statusLabel
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: progress.right
                        right: parent.right
                        leftMargin: Theme.paddingMedium
                    }

                    text: {
                        switch (appStatus.status) {
                        case AppStatus.Updating:
                            //% "Updating"
                            return qsTrId("contrac-main_la_status-updating")
                        case AppStatus.Uploading:
                            //% "Uploading"
                            return qsTrId("contrac-main_la_status-uploading")
                        case AppStatus.Downloading:
                            //% "Downloading"
                            return qsTrId("contrac-main_la_status-downloading")
                        case AppStatus.ErrorUploading:
                            //% "Error uploading"
                            return qsTrId("contrac-main_la_status-upload_error")
                        case AppStatus.ErrorDownloading:
                            //% "Error downloading"
                            return qsTrId("contrac-main_la_status-download_error")
                        case AppStatus.BluetoothBusy:
                            //% "Busy"
                            return qsTrId("contrac-main_la_status-busy")
                        case AppStatus.AtRisk:
                            //% "At risk"
                            return qsTrId("contrac-main_la_status-daily-update-required")
                        case AppStatus.DailyUpdateRequired:
                            //% "Daily update required"
                            return qsTrId("contrac-main_la_status-at-risk")
                        case AppStatus.Active:
                            //% "Active"
                            return qsTrId("contrac-main_la_status-active")
                        case AppStatus.Disabled:
                            //% "Disabled"
                            return qsTrId("contrac-main_la_status-disabled")
                        default:
                            //% "Unknown"
                            return qsTrId("contrac-main_la_status-unknown")
                        }
                    }
                    color: Theme.highlightColor

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            download.clearError()
                            upload.clearError()
                        }
                    }
                }
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Test result"
                text: qsTrId("contrac-main_la_test-result") + " : " + (testResult.possiblyAvailable
                                                                       ? testResult.testClassLabel
                                                                         //% "Unknown"
                                                                       : qsTrId("contrac-main_la_test-result-unknown"))
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                visible: testResult.possiblyAvailable
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Risk status"
                text: qsTrId("contrac-main_la_risk-status") + " : " + (!isNaN(AppSettings.summaryUpdated)
                                                                       ? riskStatus.riskClassLabel
                                                                         //% "Unknown"
                                                                       : qsTrId("contrac-main_la_risk-status-unknown"))
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Latest update"
                text: qsTrId("contrac-main_la_last-update") + " : " + (!isNaN(AppSettings.summaryUpdated)
                                                                       ? Qt.formatDateTime(AppSettings.summaryUpdated, "d MMM yyyy, hh:mm")
                                                                         //% "Never"
                                                                       : qsTrId("contrac-main_la_latest-update-never"))
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Days since last exposure"
                text: qsTrId("contrac-main_la_days-since-last-exposure") + " : " + (AppSettings.latestSummary.matchedKeyCount > 0
                                                                                    ? AppSettings.latestSummary.daysSinceLastExposure
                                                                                      //% "None recorded"
                                                                                    : qsTrId("contrac-main_la_days-since-last-exposure-none"))
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Number of matched keys"
                text: qsTrId("contrac-main_la_matched-keys") + " : " + AppSettings.latestSummary.matchedKeyCount
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Sent"
                text: qsTrId("contrac-main_sent") + " : " + dbusproxy.sentCount
                color: Theme.highlightColor
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                //% "Received"
                text: qsTrId("contrac-main_received") + " : " + dbusproxy.receivedCount
                color: Theme.highlightColor
            }

            SectionHeader {
                //% "Control"
                text: qsTrId("contrac-main_bt_actions")
            }

            TextSwitch {
                //% "Scan and send active"
                text: qsTrId("contrac-main_scan")
                width: parent.width - 2 * Theme.horizontalPageMargin
                checked: dbusproxy.isEnabled
                busy: dbusproxy.isBusy
                automaticCheck: false
                onClicked: triggerEnabled()
            }

            Button {
                id: submitKeysButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(submitKeysButton.implicitWidth, downloadButton.implicitWidth, guidButton.implicitWidth, tanButton.implicitWidth)
                enabled: !upload.uploading
                visible: testResult.currentResult === TestResult.Positive
                //% "Submit keys"
                text: qsTrId("contrac-main_bu_submit_keys")
                onClicked: {
                    upload.submitKeysAfterPositiveResult()
                    pageStack.push(Qt.resolvedUrl("UploadInfo.qml"))
                }
            }

            Button {
                id: downloadButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(submitKeysButton.implicitWidth, downloadButton.implicitWidth, guidButton.implicitWidth, tanButton.implicitWidth)
                enabled: !download.downloading && downloadAvailable
                //% "Perform daily update"
                text: qsTrId("contrac-main_bu_daily-update")
                onClicked: {
                    download.downloadLatest()
                    pageStack.push(Qt.resolvedUrl("DownloadInfo.qml"))
                }
            }

            Button {
                id: guidButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(submitKeysButton.implicitWidth, downloadButton.implicitWidth, guidButton.implicitWidth, tanButton.implicitWidth)
                //% "Enter GUID"
                text: qsTrId("contrac-main_bu_enter-guid")
                enabled: !upload.uploading
                visible: !testResult.possiblyAvailable
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("GUID.qml"))
                }
            }

            Button {
                id: tanButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(submitKeysButton.implicitWidth, downloadButton.implicitWidth, guidButton.implicitWidth, tanButton.implicitWidth)
                //% "Enter TeleTAN"
                text: qsTrId("contrac-main_bu_enter-teletan")
                enabled: !upload.uploading
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("TeleTAN.qml"))
                }
            }

            Item {
                height: Theme.paddingLarge
                width: 1
            }
        }
    }
}
