#!/bin/sh
set -eu

options_file=/data/options.json
config_file=/data/.ddns_go_config.yaml
frequency="$(jq -r '.frequency // 300' "${options_file}")"
password="$(jq -r '.pwd // empty' "${options_file}")"

# Home Assistant Ingress authenticates requests before they reach ddns-go.
export DDNS_GO_HA_INGRESS=1

if [ -n "${password}" ]; then
  /app/ddns-go -c "${config_file}" -resetPassword "${password}" || true
fi

exec /app/ddns-go -l :9876 -f "${frequency}" -c "${config_file}"
