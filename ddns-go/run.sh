#!/bin/sh
set -eu

options_file=/data/options.json
config_file=/data/.ddns_go_config.yaml
frequency="$(jq -r '.frequency // 300' "${options_file}")"
password="$(jq -r '.pwd // empty' "${options_file}")"

# Home Assistant Ingress authenticates web requests before they reach ddns-go.
export DDNS_GO_HA_INGRESS=1

if [ -z "${password}" ]; then
  password="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
fi

if [ ! -f "${config_file}" ]; then
  umask 077
  cat >"${config_file}" <<EOF
user:
  username: homeassistant
EOF
  /app/ddns-go -c "${config_file}" -resetPassword "${password}"
elif [ "$(jq -r '.pwd // empty' "${options_file}")" != "" ]; then
  /app/ddns-go -c "${config_file}" -resetPassword "${password}" || true
fi

export DDNS_GO_HA_INGRESS_PASSWORD="${password}"

exec /app/ddns-go -l :9876 -f "${frequency}" -c "${config_file}"
