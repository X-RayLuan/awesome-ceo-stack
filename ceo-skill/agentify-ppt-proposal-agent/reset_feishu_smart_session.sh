#!/bin/zsh
set -euo pipefail

SMART_SESSIONS_DIR="/Users/you/.openclaw/agents/smart/sessions"
SESSIONS_JSON="$SMART_SESSIONS_DIR/sessions.json"
STAMP="$(date +%Y-%m-%dT%H%M%S)"
BACKUP="$SMART_SESSIONS_DIR/sessions.json.bak.manual-reset-$STAMP"

if [[ -f "$SESSIONS_JSON" ]]; then
  cp "$SESSIONS_JSON" "$BACKUP"
  echo "Backed up session map to: $BACKUP"
fi

cat > "$SESSIONS_JSON" <<'EOF'
{}
EOF
echo "Reset smart session map: $SESSIONS_JSON"

openclaw gateway restart
echo "Restarted OpenClaw gateway"
