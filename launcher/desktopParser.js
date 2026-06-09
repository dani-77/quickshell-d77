// ══════════════════════════════════════════════════════
// desktopParser.js
// Parser para arquivos .desktop (Desktop Entry Specification)
// Usado pelo módulo launcher do quickshell-d77
// ══════════════════════════════════════════════════════
.pragma library

// Delimitador inserido pelo DesktopDirScanner entre cada arquivo
var FILE_DELIM = "===DESKTOP_FILE_START==="

// ──────────────────────────────────────────────────────
// Remove os "field codes" (%f %u %U ...) do campo Exec.
// O .desktop usa esses códigos para passar arquivos/URLs,
// mas para um launcher simples eles devem ser ignorados.
// ──────────────────────────────────────────────────────
function cleanExec(exec) {
    if (!exec) return ""
    return exec
        .replace(/%[fFuUdDnNickvm]/g, "")
        .replace(/\s+/g, " ")
        .trim()
}

// ──────────────────────────────────────────────────────
// Converte "true"/"false" textual em booleano.
// ──────────────────────────────────────────────────────
function toBool(val) {
    return String(val).trim().toLowerCase() === "true"
}

// ──────────────────────────────────────────────────────
// Faz o parse de UM bloco de texto correspondente a um
// único arquivo .desktop. Retorna um objeto ou null.
// Apenas a seção [Desktop Entry] é considerada.
// ──────────────────────────────────────────────────────
function parseOne(content) {
    var lines = content.split("\n")
    var inEntry = false
    var app = {
        name:       "",
        exec:       "",
        icon:       "",
        comment:    "",
        categories: "",
        terminal:   false,
        noDisplay:  false,
        hidden:     false,
        isApp:      true
    }

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === "" || line.charAt(0) === "#")
            continue

        // Cabeçalho de seção, ex: [Desktop Entry] ou [Desktop Action ...]
        if (line.charAt(0) === "[") {
            inEntry = (line === "[Desktop Entry]")
            continue
        }
        if (!inEntry)
            continue

        var eq = line.indexOf("=")
        if (eq < 0)
            continue

        var key = line.substring(0, eq).trim()
        var val = line.substring(eq + 1).trim()

        // Ignora chaves localizadas, ex: Name[pt_BR]=...
        // Mantemos somente as chaves "puras".
        switch (key) {
            case "Name":       app.name       = val;              break
            case "Exec":       app.exec       = cleanExec(val);   break
            case "Icon":       app.icon       = val;              break
            case "Comment":    app.comment    = val;              break
            case "Categories": app.categories = val;              break
            case "Terminal":   app.terminal   = toBool(val);      break
            case "NoDisplay":  app.noDisplay  = toBool(val);      break
            case "Hidden":     app.hidden     = toBool(val);      break
            case "Type":       app.isApp      = (val === "Application"); break
        }
    }

    return app
}

// ──────────────────────────────────────────────────────
// Faz o parse de toda a saída concatenada do scanner.
// Retorna um array de aplicativos válidos, já ordenado
// alfabeticamente pelo nome.
// ──────────────────────────────────────────────────────
function parseEntries(raw) {
    if (!raw) return []

    var blocks = raw.split(FILE_DELIM)
    var apps = []
    var seen = ({})

    for (var i = 0; i < blocks.length; i++) {
        var block = blocks[i]
        if (!block || block.trim() === "")
            continue

        var app = parseOne(block)

        // Filtra entradas inválidas ou que não devem aparecer.
        if (!app.isApp)        continue
        if (app.noDisplay)     continue
        if (app.hidden)        continue
        if (app.name === "")   continue
        if (app.exec === "")   continue

        // Evita duplicatas (mesmo nome + exec).
        var dedupKey = app.name + "\u0000" + app.exec
        if (seen[dedupKey]) continue
        seen[dedupKey] = true

        apps.push(app)
    }

    apps.sort(function (a, b) {
        var an = a.name.toLowerCase()
        var bn = b.name.toLowerCase()
        return an < bn ? -1 : (an > bn ? 1 : 0)
    })

    return apps
}

// ──────────────────────────────────────────────────────
// Filtra uma lista de apps por uma query (case-insensitive).
// Casa no nome, comentário ou categorias.
// ──────────────────────────────────────────────────────
function filterApps(apps, query) {
    if (!query || query.trim() === "")
        return apps

    var q = query.trim().toLowerCase()
    return apps.filter(function (a) {
        return a.name.toLowerCase().indexOf(q) >= 0
            || (a.comment    && a.comment.toLowerCase().indexOf(q)    >= 0)
            || (a.categories && a.categories.toLowerCase().indexOf(q) >= 0)
    })
}
