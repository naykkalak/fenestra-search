/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * Similarity score and category keywords adapted from MFile Search,
 * SPDX-FileCopyrightText: MCC45TR, GPL-3.0 — https://github.com/MCC45TR/kde-plasma6-widgets
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Ranking of the KRunner results:
 *   1. an exact match comes before everything (the name without its extension counts:
 *      "document1" matches "Document1.docx" exactly);
 *   2. then the order of the sections: applications, files, documents, folders,
 *      calculation, web, the rest;
 *   3. then the similarity with the typed text.
 * The results are then grouped by section. A section with a single result
 * (except applications and exact match) goes into "Other results", at the end.
 */
.pragma library

// The KRunner section names are translated by the desktop: they are recognized
// by keywords in several languages.
var MOTS = {
    app: ["application", "aplicación", "aplicacion", "aplicação", "aplicacao", "applicazione", "aplicație",
          "aplicatie", "anwendung", "toepassing", "aplikac", "sovellus", "program", "uygulama",
          "прилож", "програм", "εφαρμογ", "تطبيق", "برنامه", "앱", "애플리케이션", "アプリ", "应用"],
    calcul: ["calcul", "calculator", "unit", "currency", "einheit", "rechner", "währung", "unité", "devise",
             "calcol", "unità", "valuta", "calculadora", "unidad", "moneda", "kalkulator", "jednost", "walut",
             "hesap", "birim", "döviz", "калькуля", "единиц", "валют", "計算", "単位", "通貨", "计算", "单位", "货币"],
    document: ["document", "belge", "dokument", "documento", "documente", "dokumen", "документ", "έγγραφο",
               "مستند", "문서", "ドキュメント", "文档"],
    dossier: ["folder", "place", "ordner", "orte", "dossier", "emplacement", "carpeta", "lugares", "pasta",
              "cartella", "map", "katalog", "kansio", "plats", "klasör", "yerler", "папк", "мест", "φάκελ",
              "مجلد", "폴더", "フォルダー", "文件夹"],
    fichier: ["file", "datei", "fichier", "archivo", "ficheiro", "bestand", "plik", "soubor", "tiedosto",
              "fil", "dosya", "файл", "αρχείο", "ملف", "파일", "ファイル", "文件"],
    image: ["image", "picture", "photo", "bild", "foto", "imagem", "immagine", "afbeeld", "obraz", "resim",
            "görsel", "изображ", "εικόν", "صورة", "이미지", "画像", "图像", "图片"],
    web: ["web", "browser", "bookmark", "internet", "lesezeichen", "navigateur", "signet", "marcador",
          "segnalibro", "bladwijzer", "zakład", "yer imi", "брауз", "заклад", "متصفح", "북마크", "ブックマーク", "书签"],
    autre: ["other", "andere", "autre", "otro", "outro", "altro", "overig", "inne", "diğer", "друг",
            "άλλ", "أخرى", "기타", "その他", "其他"]
};

function minuscule(v) {
    return String(v || "").toLocaleLowerCase().replace(/̇/g, "");
}

function contient(v, liste) {
    var t = minuscule(v);
    for (var i = 0; i < liste.length; i++)
        if (t.indexOf(liste[i]) !== -1) return true;
    return false;
}

function extension(url) {
    var p = minuscule(url).split(/[?#]/)[0];
    var s = p.lastIndexOf("/"), d = p.lastIndexOf(".");
    return d > s + 1 ? p.substring(d + 1) : "";
}

function estCalcul(rubrique, icone, id) {
    return contient(rubrique, MOTS.calcul)
        || contient(icone, ["calculator", "accessories-calculator", "currency"])
        || contient(id, ["calculator", "unitconverter", "converter"]);
}

function genre(rubrique) {
    if (estCalcul(rubrique)) return "calcul";
    if (contient(rubrique, MOTS.app)) return "app";
    if (contient(rubrique, MOTS.document)) return "document";
    if (contient(rubrique, MOTS.dossier)) return "dossier";
    if (contient(rubrique, MOTS.fichier)) return "fichier";
    if (contient(rubrique, MOTS.web)) return "web";
    if (contient(rubrique, MOTS.autre)) return "autre";
    return "inconnu";
}

// smaller = higher in the list
function priorite(rubrique) {
    var g = genre(rubrique);
    return {app: 1, fichier: 2, document: 3, dossier: 4, calcul: 5, web: 6, autre: 100}[g] || 50;
}

function estApplication(rubrique, url, id, icone) {
    if (minuscule(url).endsWith(".desktop") || minuscule(id).endsWith(".desktop")) return true;
    var i = minuscule(icone);
    if (i === "application-x-executable" || i.indexOf("applications-") === 0
            || i.indexOf("system-settings") === 0 || i.indexOf("preferences-") === 0)
        return true;
    return contient(rubrique, MOTS.app);
}

function estDossier(rubrique, url, icone) {
    return minuscule(url).endsWith("/") || minuscule(icone).indexOf("folder") !== -1
        || contient(rubrique, MOTS.dossier);
}

// Software Center suggestions ("Get …"): applications not installed,
// absent from the Windows 11 search -> hidden
function estLogitheque(rubrique, url) {
    return minuscule(url).indexOf("appstream:") === 0
        || ["logithèque", "software center", "software centre", "softwarecenter", "discover",
            "centro de software", "centro software", "centre logiciel"].indexOf(minuscule(rubrique)) !== -1;
}

// filter chips: All, Applications, Documents, Images, Folders, Web
function passeFiltre(filtre, r) {
    var url = minuscule(r.url), ic = minuscule(r.decoration), ext = extension(r.url);
    switch (filtre) {
    case "Apps":
        return estApplication(r.category, r.url, r.duplicateId, r.decoration);
    case "Docs":
        return contient(r.category, MOTS.document) || ic.indexOf("document") !== -1 || ic.indexOf("text") !== -1
            || ["txt", "md", "pdf", "odt", "doc", "docx", "rtf", "epub", "xls", "xlsx", "ods", "ppt", "pptx", "odp"].indexOf(ext) !== -1;
    case "Images":
        return contient(r.category, MOTS.image) || ic.indexOf("image") !== -1 || ic.indexOf("photo") !== -1
            || ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tif", "tiff", "avif", "heic"].indexOf(ext) !== -1;
    case "Folders":
        return estDossier(r.category, r.url, r.decoration);
    case "Web":
        return url.indexOf("http://") === 0 || url.indexOf("https://") === 0 || url.indexOf("www") === 0
            || ic.indexOf("web") !== -1 || ic.indexOf("globe") !== -1 || contient(r.category, MOTS.web);
    }
    return true;
}

// similarity between the typed text q and the name t (already lowercase), from 0 to 1
function ressemblance(q, t) {
    if (t === q) return 1;
    var i = t.indexOf(q);
    if (i === 0) return 0.95;
    if (i !== -1) return Math.max(0.5, 0.85 - i * 0.01);
    var qi = 0;
    for (var ti = 0; ti < t.length && qi < q.length; ti++)
        if (t.charAt(ti) === q.charAt(qi)) qi++;
    if (qi === q.length) return 0.3 + (q.length / t.length) * 0.3;
    var initiales = "", dansMot = false;
    for (var k = 0; k < t.length; k++) {
        var c = t.charAt(k);
        if (c === " " || c === "-" || c === "_" || c === ".") dansMot = false;
        else if (!dansMot) { initiales += c; dansMot = true; }
    }
    return initiales.indexOf(q) !== -1 ? 0.6 : 0;
}

function exact(nom, q) {
    var p = nom.lastIndexOf(".");
    return nom === q || (p > 0 && nom.substring(0, p) === q);
}

// raw: [{display, decoration, category, url, subtext, duplicateId, index}]
// returns the flat list, each item carrying its display section (rubrique)
function classer(bruts, texte, filtre, maximum, autresResultats) {
    var q = minuscule(texte);
    var notes = [];
    for (var i = 0; i < bruts.length; i++) {
        var r = bruts[i];
        if (filtre !== "All" && !passeFiltre(filtre, r)) continue;
        var nom = minuscule(r.display);
        var note = ressemblance(q, nom);
        if (note < 1 && exact(nom, q)) note = 1;
        notes.push({r: r, prio: priorite(r.category), note: note, ordre: i});
    }
    notes.sort(function(a, b) {
        var ea = a.note >= 1 ? 1 : 0, eb = b.note >= 1 ? 1 : 0;
        if (ea !== eb) return eb - ea;
        if (a.prio !== b.prio) return a.prio - b.prio;
        if (a.note !== b.note) return b.note - a.note;
        return a.ordre - b.ordre;
    });
    if (maximum > 0 && notes.length > maximum) notes = notes.slice(0, maximum);

    // grouping by section, in order of appearance
    var groupes = {}, ordre = [];
    for (var j = 0; j < notes.length; j++) {
        var c = notes[j].r.category || "Other";
        if (!groupes[c]) { groupes[c] = []; ordre.push(c); }
        groupes[c].push(notes[j].r);
    }
    var gardees = [], exactes = [], autres = [];
    for (var k = 0; k < ordre.length; k++) {
        var nomR = ordre[k], items = groupes[nomR], aExact = false;
        for (var x = 0; x < items.length; x++)
            if (exact(minuscule(items[x].display), q)) { aExact = true; break; }
        if (items.length <= 1 && !contient(nomR, MOTS.app) && !aExact) {
            for (var m = 0; m < items.length; m++) autres.push(items[m]);
        } else {
            gardees.push(nomR);
            if (aExact) exactes.push(nomR);
        }
    }
    gardees.sort(function(a, b) { return priorite(a) - priorite(b); });
    // the section containing an exact match comes first
    var finales = gardees.filter(function(n) { return exactes.indexOf(n) !== -1; })
        .concat(gardees.filter(function(n) { return exactes.indexOf(n) === -1; }));

    var liste = [];
    for (var n = 0; n < finales.length; n++)
        for (var p = 0; p < groupes[finales[n]].length; p++) {
            groupes[finales[n]][p].rubrique = finales[n];
            liste.push(groupes[finales[n]][p]);
        }
    for (var a = 0; a < autres.length; a++) {
        autres[a].rubrique = autresResultats;
        liste.push(autres[a]);
    }
    return liste;
}

// path shown under the name: relative to the home folder
function cheminCourt(r) {
    if (r.web) return r.subtext;      // web search: the engine's site
    var p = String(r.url || "").replace("file://", "").replace(/^\/home\/[^\/]+\//, "");
    return p || r.subtext || "";
}
