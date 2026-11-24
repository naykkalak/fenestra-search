/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "Moteurs.js" as Moteurs

KCM.SimpleKCM {
    property alias cfg_largeurCran: largeur.value
    property alias cfg_modeLoupe: loupeSeule.checked
    property string cfg_moteurWeb

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Search box width:")
            QQC2.Slider {
                id: largeur
                enabled: !loupeSeule.checked
                from: 0
                to: 12
                stepSize: 1
                snapMode: QQC2.Slider.SnapAlways
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            QQC2.Label { text: largeur.value }
        }

        Item { implicitHeight: Kirigami.Units.largeSpacing }   // 2.0: some space around the checkbox

        QQC2.CheckBox {
            id: loupeSeule
            text: i18n("Show only a magnifier in the taskbar")
        }

        Item { implicitHeight: Kirigami.Units.largeSpacing }

        QQC2.ComboBox {
            id: moteur
            Kirigami.FormData.label: i18n("Web search engine:")
            textRole: "nom"
            valueRole: "cle"
            model: [{ cle: "kde", nom: i18n("Follow KDE settings") }].concat(Moteurs.LISTE.map(function(m) {
                return { cle: m.cle, nom: m.nom };
            }))
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(cfg_moteurWeb))
            onActivated: cfg_moteurWeb = currentValue
        }
        QQC2.Label {
            text: i18n("“Follow KDE settings” uses the default engine chosen in System Settings › Web Search Keywords.")
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }
    }
}
