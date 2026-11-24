/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// "About" (1.1): same layout as the one in This PC, with the series logo.
// Plasma window, like the search window: under Wayland, only a window
// of this type is sure to come in front of it; the search stays open behind.
// No "new version" checkbox: the widget is updated through KDE.
PlasmaCore.Dialog {
    id: aPropos

    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: false
    visible: false

    function ouvrir() {
        visible = true;
        Qt.callLater(centrer);
        requestActivate();
    }
    function fermer() { visible = false; }
    // centered on the panel's screen
    function centrer() {
        var e = root.screenGeometry;
        x = Math.round(e.x + (e.width - width) / 2);
        y = Math.round(e.y + (e.height - height) / 2);
    }

    mainItem: Item {
        width: 480
        height: colonne.implicitHeight + 40 + 16 + 50   // title bar + content + button
        focus: true
        Keys.onEscapePressed: aPropos.fermer()

        // title bar, like the "About" window of This PC
        Item {
            id: barreTitre
            width: parent.width
            height: 32
            QQC2.Label {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: i18n("About Fenestra Search")
            }
        }

        QQC2.Button {   // "Close" anchored at the bottom right, like the other Fenestra windows
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            text: i18n("Close")
            onClicked: aPropos.fermer()
        }

        ColumnLayout {
            id: colonne
            x: 16
            y: 40   // below the title bar
            width: 480 - 32
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Image {   // 2.0: magnifier from the windows-modern theme
                    source: Qt.resolvedUrl("../images/preferences-system-search.svg")
                    mirror: true   // 2.0: handle at the bottom right, like the other search boxes
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    sourceSize.width: 56 * Screen.devicePixelRatio
                    sourceSize.height: 56 * Screen.devicePixelRatio   // 2.0: sharp edges, like Menu 11
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: false
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QQC2.Label {
                        text: "Fenestra Search"
                        font.pixelSize: 22
                        font.bold: true
                    }
                    QQC2.Label {
                        text: i18n("Version %1", Plasmoid.metaData.version)
                        opacity: 0.75
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            RowLayout {   // the series logo in front of its description
                Layout.fillWidth: true
                spacing: 12
                Image {
                    source: Qt.resolvedUrl("../images/fenestra-logo.svg")
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    sourceSize.width: 40 * Screen.devicePixelRatio
                    sourceSize.height: 40 * Screen.devicePixelRatio   // 2.0: sharp edges, like Menu 11
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: false
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: i18n("Part of the Fenestra series, which gives KDE Plasma the look of a Windows 11 desktop.")
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: i18n("Author: %1", "naykkalak")
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: i18n("License: %1", i18n("GPL-3.0 or later"))
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                opacity: 0.75
                text: i18n("This software is neither affiliated with nor endorsed by Microsoft Corporation. Windows is a trademark of Microsoft Corporation.")
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                opacity: 0.75
                text: i18n("Result ranking adapted from MFile Search by MCC45TR (GPL-3.0).")
            }
        }
    }
}
