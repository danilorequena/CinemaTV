#!/bin/sh
#
# Xcode Cloud clona o repo limpo, sem os plists de secrets (gitignored),
# mas eles estão na fase Copy Bundle Resources — sem o arquivo o build
# falha com "Build input file cannot be found". Este script gera
# placeholders; o app já trata placeholder/ausência como "sem credencial"
# (feedback vira somente leitura, integrações ficam desabilitadas).
#
set -e

RESOURCES_DIR="$CI_PRIMARY_REPOSITORY_PATH/CinemaTV/Resources"

if [ ! -f "$RESOURCES_DIR/GitHub.plist" ]; then
    cat > "$RESOURCES_DIR/GitHub.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ISSUES_TOKEN</key>
    <string>PASTE_GITHUB_ISSUES_TOKEN</string>
</dict>
</plist>
EOF
    echo "GitHub.plist placeholder criado."
fi

if [ ! -f "$RESOURCES_DIR/Trakt.plist" ]; then
    cat > "$RESOURCES_DIR/Trakt.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>YOUR_TRAKT_CLIENT_ID</string>
    <key>CLIENT_SECRET</key>
    <string>YOUR_TRAKT_CLIENT_SECRET</string>
    <key>REDIRECT_URI</key>
    <string>cinematv://trakt-auth</string>
</dict>
</plist>
EOF
    echo "Trakt.plist placeholder criado."
fi
