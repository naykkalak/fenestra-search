/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.kicker 0.1 as Kicker
import "Classement.js" as Classement

// Right pane (1.1), as on Windows 11: the selected result in large size,
// "Open", the other actions behind an arrow, and for an application
// the recent files opened with it (same source as the Start menu: Kicker).
Rectangle {
    id: volet

    property var resultat: null
    signal lancer(var resultat)
    signal fini()
    // "Open location": first KRunner's own action (it knows how to bring
    // the file manager window to the front); the window answers with
    // montrerEmplacement() if the result does not have this action.
    signal emplacement(var resultat)

    readonly property color teinte: Kirigami.Theme.textColor
    readonly property bool sombre: teinte.hslLightness > 0.5
    readonly property color survolCouleur: sombre ? "#33ffffff" : "#a6ffffff"
    readonly property color traitCouleur: sombre ? "#1affffff" : "#14000000"

    color: sombre ? "#26ffffff" : "#80ffffff"   // same background as the home tiles
    radius: 8
    border.width: 1
    border.color: traitCouleur
    clip: true

    // ── What the result is ──
    readonly property string url: resultat ? String(resultat.url || "") : ""
    readonly property bool web: resultat ? resultat.web === true : false
    readonly property bool calcul: resultat ? Classement.estCalcul(resultat.category, resultat.decoration, resultat.duplicateId) : false
    readonly property bool parametre: resultat !== null && !web
        && (/kcm_|systemsettings/i.test(url + " " + (resultat.duplicateId || ""))
            || /setting|paramètre|configuration du système|einstellung|configuración|impostazion|instelling|ustawieni|definiç|configuraç|настройк|параметр|ayar|設定|设置|設置/i
                   .test(String(resultat.category || "")))
    readonly property bool application: resultat !== null && !web && !calcul && !parametre
        && Classement.estApplication(resultat.category, url, resultat.duplicateId, resultat.decoration)
    // local path (without file://, decoded); empty if it is not a file
    // (KDE's file search often gives no address: only the name
    //  and the folder, "~/Images"; the path is then rebuilt)
    readonly property string maison: String(StandardPaths.writableLocation(StandardPaths.HomeLocation)).replace("file://", "")
    readonly property string chemin: {
        if (!resultat || web || calcul || application || parametre) return "";
        var u = url;
        if (u.indexOf("file://") === 0) u = u.substring(7);
        else if (u.indexOf("/") !== 0) {
            var d = String(resultat.subtext || "");
            if (u !== "" || !/^(~|\/)/.test(d) || !resultat.display) return "";
            u = d.replace(/^~/, maison).replace(/\/$/, "") + "/" + resultat.display;
            return u;
        }
        try { u = decodeURIComponent(u); } catch (e) {}
        return u;
    }
    readonly property bool dossier: chemin !== "" && Classement.estDossier(resultat.category, url, resultat.decoration)
    readonly property string ext: Classement.extension(chemin)
    readonly property bool image: !dossier && ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tif", "tiff", "avif"].indexOf(ext) !== -1
    readonly property bool document: !dossier && (Classement.genre(resultat ? resultat.category : "") === "document"
        || ["pdf", "odt", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "ods", "odp", "csv", "epub", "txt", "md", "rtf"].indexOf(ext) !== -1)
    readonly property string typeTexte: {
        if (!resultat) return "";
        if (web) return i18n("Web search");
        if (calcul) return i18n("Calculation");
        if (parametre) return i18n("Setting");
        if (application) return i18n("Application");
        if (dossier) return i18n("Folder");
        if (image) return i18n("Image");
        if (document) return i18n("Document");
        return chemin !== "" ? i18n("File") : "";
    }

    // preview: the image itself, or the thumbnail already made by KDE for a document
    readonly property string apercu: {
        if (chemin === "" || dossier) return "";
        if (image) return "file://" + encodeURI(chemin).replace(/#/g, "%23").replace(/\?/g, "%3F");
        if (!document) return "";
        var uri = "file://" + encodeURI(chemin).replace(/#/g, "%23").replace(/\?/g, "%3F");
        var cache = String(StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)).replace("file://", "");
        return "file://" + encodeURI(cache + "/thumbnails/normal/" + Qt.md5(uri) + ".png");
    }

    // ── Application: recent items and its own actions, like the Start menu right click ──
    // The application is requested again from KRunner through Kicker: its row carries the list of actions
    // (application actions, recent files, edit, manage in Discover…).
    readonly property string cible: {          // application .desktop identifier
        if (!application) return "";
        var u = /\.desktop$/i.test(url) ? url : String(resultat.duplicateId || "");
        return u.replace(/^.*[:\/]/, "");
    }
    property var recents: []
    property var actionsApp: []
    property int rangApp: -1
    property bool deplie: true          // expanded by default: the feature is visible

    Kicker.RunnerModel {
        id: chercheApp
        runners: ["krunner_services"]
        mergeResults: true
        query: volet.application ? String(volet.resultat.display || "") : ""
    }
    Instantiator {
        id: lignesApp
        model: chercheApp.count > 0 ? chercheApp.modelForRow(0) : null
        delegate: QtObject {
            property int rang: index
            property var actions: model.actionList || []
            property string ident: String(model.favoriteId || model.url || "")
            property string nom: String(model.display || "")
        }
        onObjectAdded: relireTimer.restart()
        onObjectRemoved: relireTimer.restart()
    }
    Timer { id: relireTimer; interval: 30; onTriggered: volet.relire() }

    function relire() {
        var rec = [], aut = [], trouve = null;
        if (application) {
            for (var i = 0; i < lignesApp.count; i++) {
                var o = lignesApp.objectAt(i);
                if (!o) continue;
                if (cible !== "" && o.ident.replace(/^.*[:\/]/, "") === cible) { trouve = o; break; }
                if (!trouve && o.nom === String(resultat.display || "")) trouve = o;
            }
        }
        rangApp = trouve ? trouve.rang : -1;
        if (trouve) {
            for (var j = 0; j < trouve.actions.length; j++) {
                var a = trouve.actions[j];
                if (!a || !a.text || !a.actionId || a.type === "title" || a.type === "separator") continue;
                var id = String(a.actionId).toLowerCase();
                if (id.indexOf("forget") !== -1) continue;              // "Forget recent files"
                if (id.indexOf("recent") !== -1) { if (rec.length < 10) rec.push(a); }
                else if (aut.length < 8) aut.push(a);
            }
        }
        recents = rec;
        actionsApp = aut;
    }
    onResultatChanged: relireTimer.restart()

    function declencher(a) {
        var m = chercheApp.count > 0 ? chercheApp.modelForRow(0) : null;
        if (m && rangApp >= 0) m.trigger(rangApp, a.actionId, a.actionArgument);
        volet.fini();
    }

    // ── File: open the location (standard file manager) and copy the path ──
    Plasma5Support.DataSource {
        id: commande
        engine: "executable"
        onNewData: (source, donnees) => disconnectSource(source)
    }
    function montrerEmplacement() {
        var uri = "file://" + encodeURI(chemin).replace(/#/g, "%23").replace(/\?/g, "%3F")
                  .replace(/'/g, "%27").replace(/,/g, "%2C");
        commande.connectSource("dbus-send --session --type=method_call --dest=org.freedesktop.FileManager1 "
            + "/org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems "
            + "array:string:'" + uri + "' string:''");
        volet.fini();
    }
    TextEdit { id: pressePapier; visible: false }
    function copierChemin() {
        pressePapier.text = chemin;
        pressePapier.selectAll();
        pressePapier.copy();
        volet.fini();
    }

    // actions under the arrow, depending on the type
    readonly property var autres: {
        var l = [];
        if (application) {
            for (var i = 0; i < actionsApp.length; i++)
                l.push({ texte: actionsApp[i].text, icone: actionsApp[i].icon || "", action: actionsApp[i] });
        } else if (chemin !== "") {
            if (!dossier) l.push({ texte: i18n("Open file location"), icone: "folder-open", genre: "emplacement" });
            l.push({ texte: i18n("Copy path"), icone: "edit-copy", genre: "copier" });
        }
        return l;
    }
    function executer(a) {
        if (a.action) declencher(a.action);
        else if (a.genre === "emplacement") volet.emplacement(volet.resultat);
        else if (a.genre === "copier") copierChemin();
    }

    // an action row: icon + text, background on hover
    component LigneAction: Rectangle {
        id: ligneAction
        property string texte: ""
        property var icone: ""
        property string secours: ""
        signal choisie()
        Layout.fillWidth: true
        implicitHeight: 34
        radius: 4
        color: survolLigne.hovered ? volet.survolCouleur : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10
            Kirigami.Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: ligneAction.icone
                fallback: ligneAction.secours
                color: volet.teinte
            }
            Text {
                Layout.fillWidth: true
                text: ligneAction.texte
                color: volet.teinte
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                elide: Text.ElideRight
            }
        }
        HoverHandler { id: survolLigne; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: ligneAction.choisie() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0
        visible: volet.resultat !== null

        // large icon or preview
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: apercuImage.status === Image.Ready ? 150 : 80
            Image {
                id: apercuImage
                anchors.fill: parent
                source: volet.apercu
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 320
                sourceSize.height: 300
                visible: status === Image.Ready
            }
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 64
                height: 64
                source: volet.calcul ? "accessories-calculator" : (volet.resultat ? volet.resultat.decoration : "")
                visible: apercuImage.status !== Image.Ready
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 10
            horizontalAlignment: Text.AlignHCenter
            text: volet.resultat ? (volet.resultat.display || "") : ""
            color: volet.teinte
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.35)
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 2
            horizontalAlignment: Text.AlignHCenter
            text: volet.typeTexte
            color: Qt.rgba(volet.teinte.r, volet.teinte.g, volet.teinte.b, 0.6)
            font.family: Kirigami.Theme.smallFont.family
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        Rectangle { Layout.fillWidth: true; Layout.topMargin: 14; Layout.bottomMargin: 6; height: 1; color: volet.traitCouleur }

        LigneAction {
            texte: i18n("Open")
            icone: "open-link"
            secours: "document-open"
            onChoisie: volet.lancer(volet.resultat)
        }

        // the arrow: expands the other actions
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 24
            visible: volet.autres.length > 0
            Rectangle { anchors.left: parent.left; anchors.right: fleche.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; height: 1; color: volet.traitCouleur }
            Rectangle {
                id: fleche
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 24
                radius: 4
                color: survolFleche.hovered ? volet.survolCouleur : "transparent"
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: volet.deplie ? "go-up" : "go-down"
                    color: volet.teinte
                }
                HoverHandler { id: survolFleche; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: volet.deplie = !volet.deplie }
            }
        }
        Repeater {
            model: volet.deplie ? volet.autres : []
            delegate: LigneAction {
                required property var modelData
                texte: modelData.texte
                icone: modelData.icone
                onChoisie: volet.executer(modelData)
            }
        }

        // recent files of the application
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.bottomMargin: 4
            Layout.leftMargin: 8
            visible: volet.recents.length > 0
            text: i18n("Recent")
            color: volet.teinte
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            font.bold: true
        }
        Repeater {
            model: volet.recents
            delegate: LigneAction {
                required property var modelData
                texte: modelData.text
                icone: modelData.icon || "text-x-generic"
                onChoisie: volet.declencher(modelData)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
