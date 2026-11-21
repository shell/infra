#!/bin/bash
# Fetch a community dashboard from grafana.com and add it to the provisioned
# Grafana dashboards folder so it's version-controlled and survives redeploys.
#
# Usage:
#   scripts/add-grafana-dashboard.sh <dashboard-id> [output-name]   # add new
#   scripts/add-grafana-dashboard.sh --update <existing-name>       # refresh to latest revision
#
# Example:
#   scripts/add-grafana-dashboard.sh 1860 node-exporter-full
#   scripts/add-grafana-dashboard.sh --update node-exporter-full
#   (find dashboard IDs at https://grafana.com/grafana/dashboards/)
set -e

DEST_DIR="$(dirname "$0")/../cluster/monitor/grafana/config/dashboards"

if [ "$1" = "--update" ]; then
    NAME="${2%.json}"
    DEST_FILE="$DEST_DIR/$NAME.json"
    if [ ! -f "$DEST_FILE" ]; then
        echo "ERROR: $DEST_FILE does not exist"
        exit 1
    fi
    DASHBOARD_ID=$(python3 -c "import json; print(json.load(open('$DEST_FILE'))['gnetId'])")
    if [ -z "$DASHBOARD_ID" ] || [ "$DASHBOARD_ID" = "None" ]; then
        echo "ERROR: $DEST_FILE has no gnetId - it wasn't downloaded from grafana.com, can't auto-update"
        exit 1
    fi
    OUTPUT_NAME="$NAME"
else
    DASHBOARD_ID="$1"
    OUTPUT_NAME="$2"
fi

if [ -z "$DASHBOARD_ID" ]; then
    echo "Usage: $0 <dashboard-id> [output-name]"
    echo "       $0 --update <existing-name>"
    echo "Find IDs at https://grafana.com/grafana/dashboards/"
    exit 1
fi

echo "Looking up dashboard $DASHBOARD_ID on grafana.com..."
META=$(curl -sf "https://grafana.com/api/dashboards/$DASHBOARD_ID")
if [ -z "$META" ]; then
    echo "ERROR: could not fetch metadata for dashboard $DASHBOARD_ID"
    exit 1
fi

REVISION=$(echo "$META" | python3 -c "import json,sys; print(json.load(sys.stdin)['revision'])")
SLUG=$(echo "$META" | python3 -c "import json,sys; print(json.load(sys.stdin)['slug'])")
NAME="${OUTPUT_NAME:-$SLUG}"
DEST_FILE="$DEST_DIR/$NAME.json"

echo "Downloading revision $REVISION ($SLUG)..."
curl -sf "https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/$REVISION/download" -o "$DEST_FILE"

# Dashboards exported with "${DS_*}" input placeholders only get resolved by
# Grafana's UI import flow, not file-based provisioning - rewrite them to point
# straight at our fixed datasource uids (see config/datasource.yml), chosen by
# the input's plugin type. Datasource-picker variables get the same default.
python3 - "$DEST_FILE" <<'PY'
import json, re, sys

UIDS = {"prometheus": "prometheus", "influxdb": "influxdb-proxmox"}
NAMES = {"prometheus": "Prometheus", "influxdb": "InfluxDB (Proxmox)"}

path = sys.argv[1]
text = open(path).read()
dash = json.loads(text)

for inp in dash.get("__inputs", []):
    uid = UIDS.get(inp.get("pluginId"))
    if inp.get("type") == "datasource" and uid:
        text = text.replace("${%s}" % inp["name"], uid)
# Older exports without __inputs
text = re.sub(r"\$\{(DS_PROMETHEUS|ds_prometheus)\}", "prometheus", text)

dash = json.loads(text)
for var in dash.get("templating", {}).get("list", []):
    plugin = var.get("query")
    if var.get("type") == "datasource" and plugin in UIDS:
        var["current"] = {"selected": True, "text": NAMES[plugin], "value": UIDS[plugin]}

json.dump(dash, open(path, "w"), indent=2)
leftover = sorted(set(re.findall(r"\$\{DS_[^}]+\}", json.dumps(dash))))
if leftover:
    sys.exit("ERROR: unresolved datasource placeholders: %s" % ", ".join(leftover))
PY

echo ""
echo "Saved to $DEST_FILE"
echo "Grafana will pick it up automatically (checks every 30s, or on redeploy)."
echo "Don't forget to: git add $DEST_FILE"
