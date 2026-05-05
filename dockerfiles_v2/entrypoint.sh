#!/bin/bash
set -e

configure_grafana_https() {
  local grafana_config="/etc/grafana/grafana.ini"
  local https_enabled="${GRAFANA_HTTPS_ENABLED:-false}"
  local cert_file="${GRAFANA_CERT_FILE:-/etc/grafana/certs/tls.crt}"
  local cert_key="${GRAFANA_CERT_KEY:-/etc/grafana/certs/tls.key}"
  local staged_cert_dir="/run/spark-dashboard/grafana-certs"
  local staged_cert_file="${staged_cert_dir}/tls.crt"
  local staged_cert_key="${staged_cert_dir}/tls.key"
  local root_url="${GRAFANA_ROOT_URL:-}"

  case "${https_enabled}" in
    true|TRUE|1|yes|YES)
      sed -i '/^; spark-dashboard HTTPS settings$/,/^; end spark-dashboard HTTPS settings$/d' "${grafana_config}"
      local cert_dir
      cert_dir="$(dirname "${cert_file}")"
      if [[ ! -r "${cert_file}" ]]; then
        echo "Grafana HTTPS is enabled but certificate file is not readable: ${cert_file}" >&2
        echo "Contents of ${cert_dir}:" >&2
        ls -la "${cert_dir}" >&2 || true
        exit 1
      fi
      if [[ ! -r "${cert_key}" ]]; then
        echo "Grafana HTTPS is enabled but certificate key is not readable: ${cert_key}" >&2
        echo "Contents of $(dirname "${cert_key}"):" >&2
        ls -la "$(dirname "${cert_key}")" >&2 || true
        exit 1
      fi
      install -d -o grafana -g grafana -m 0750 "${staged_cert_dir}"
      install -o grafana -g grafana -m 0644 "${cert_file}" "${staged_cert_file}"
      install -o grafana -g grafana -m 0640 "${cert_key}" "${staged_cert_key}"

      {
        echo ""
        echo "; spark-dashboard HTTPS settings"
        echo "[server]"
        echo "protocol = https"
        echo "cert_file = ${staged_cert_file}"
        echo "cert_key = ${staged_cert_key}"
        if [[ -n "${root_url}" ]]; then
          echo "root_url = ${root_url}"
        fi
        echo "; end spark-dashboard HTTPS settings"
      } >> "${grafana_config}"
      ;;
  esac
}

configure_grafana_admin_password() {
  local grafana_config="/etc/grafana/grafana.ini"
  local admin_password="${GRAFANA_ADMIN_PASSWORD:-${GF_SECURITY_ADMIN_PASSWORD:-}}"
  local admin_password_dir="/run/spark-dashboard/grafana-admin"
  local admin_password_file="${admin_password_dir}/admin-password"

  if [[ -n "${admin_password}" ]]; then
    install -d -o grafana -g grafana -m 0750 "${admin_password_dir}"
    printf '%s' "${admin_password}" > "${admin_password_file}"
    chown grafana:grafana "${admin_password_file}"
    chmod 0640 "${admin_password_file}"

    sed -i '/^; spark-dashboard admin password settings$/,/^; end spark-dashboard admin password settings$/d' "${grafana_config}"
    {
      echo ""
      echo "; spark-dashboard admin password settings"
      echo "[security]"
      echo "admin_password = \$__file{${admin_password_file}}"
      echo "; end spark-dashboard admin password settings"
    } >> "${grafana_config}"
  fi
}

configure_grafana_admin_password
configure_grafana_https

wait_for_grafana() {
  local protocol="http"
  local curl_options=("-fsS")

  case "${GRAFANA_HTTPS_ENABLED:-false}" in
    true|TRUE|1|yes|YES)
      protocol="https"
      curl_options=("-kfsS")
      ;;
  esac

  for _ in {1..60}; do
    if curl "${curl_options[@]}" "${protocol}://localhost:3000/api/health" >/dev/null 2>&1; then
      return 0
    fi
    if ! pgrep -u grafana -f grafana >/dev/null 2>&1; then
      return 1
    fi
    sleep 1
  done

  return 1
}

# Start the services
service grafana-server start || true
if ! wait_for_grafana; then
  echo "Grafana failed to start. Recent Grafana logs:" >&2
  tail -n 200 /var/log/grafana/grafana.log >&2 || true
  echo "Effective Grafana server settings:" >&2
  sed -n '/^\[server\]$/,/^\[/p' /etc/grafana/grafana.ini >&2 || true
  exit 1
fi
service telegraf start
./victoria-metrics-prod

# when running with docker run -d option this keeps the container running
tail -f /dev/null
