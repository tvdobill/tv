#!/bin/bash

set -e

REPO_API="https://api.github.com/repos/tvdobill/tvdobill.github.io/contents/repo"
WORKDIR="$HOME/kodi-repo-work"
REPODIR="$WORKDIR/repo"

mkdir -p "$REPODIR"
cd "$WORKDIR"

echo "🔍 Lendo addons do GitHub (API)..."

ZIP_URLS=$(curl -s "$REPO_API" \
  | grep '"download_url"' \
  | grep '.zip"' \
  | sed 's/.*"download_url": "\(.*\)".*/\1/')

if [ -z "$ZIP_URLS" ]; then
  echo "❌ Nenhum addon ZIP encontrado no GitHub."
  exit 1
fi

echo "📦 Baixando addons..."
rm -f "$REPODIR"/*.zip

for url in $ZIP_URLS; do
  echo "⬇️ $(basename "$url")"
  wget -q -P "$REPODIR" "$url"
done

echo "🧩 Gerando addons.xml..."
echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' > "$REPODIR/addons.xml"
echo '<addons>' >> "$REPODIR/addons.xml"

for zip in "$REPODIR"/*.zip; do
  echo "📦 Processando $(basename "$zip")"
  unzip -p "$zip" addon.xml >> "$REPODIR/addons.xml" 2>/dev/null || true
done

echo '</addons>' >> "$REPODIR/addons.xml"

md5sum "$REPODIR/addons.xml" | awk '{print $1}' > "$REPODIR/addons.xml.md5"

echo "🌐 Criando index.html..."
cat > "$REPODIR/index.html" <<EOF
<html>
<head><title>TV DO BILL - Repositório Kodi</title></head>
<body>
<h1>TV DO BILL - Repositório Kodi</h1>
<ul>
EOF

for f in "$REPODIR"/*; do
  file=$(basename "$f")
  echo "<li><a href=\"$file\">$file</a></li>" >> "$REPODIR/index.html"
done

cat >> "$REPODIR/index.html" <<EOF
</ul>
</body>
</html>
EOF

echo
echo "✅ Repositório Kodi gerado com sucesso!"
echo "📁 Arquivos prontos em:"
echo "👉 $REPODIR"
echo
echo "➡️ Copie TODO o conteúdo dessa pasta para:"
echo "https://github.com/tvdobill/tvdobill.github.io/tree/main/repo"

