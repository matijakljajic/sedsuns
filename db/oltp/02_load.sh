#!/usr/bin/env bash
set -euo pipefail

total_files=$(find seed-data -type f -name '*.csv' | wc -l)
completed_files=0
db_password="SEDS_OLTP"

if ! podman exec sedsuns-oracle test -d /seed-data \
  || ! podman exec sedsuns-oracle test -d /load-control; then
  echo "The container needs the /seed-data and /load-control mounts." >&2
  exit 1
fi

if ! podman exec sedsuns-oracle sh -c 'command -v sqlldr >/dev/null'; then
  echo "sqlldr is not available in sedsuns-oracle." >&2
  exit 1
fi

render_progress() {
  local percent filled bar
  percent=$((completed_files * 100 / total_files))
  filled=$((percent * 30 / 100))
  bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
  printf '\r\033[2K[%3d%%] [%-30s] %d/%d  %s' "$percent" "$bar" "$completed_files" "$total_files" "$1"
}

load_table() {
  local table_name="$1"
  local data_file file_name load_log container_data_file

  for data_file in "seed-data/$table_name"/*.csv; do
    file_name="${data_file##*/}"
    load_log=$(mktemp /tmp/sedsuns-sqlldr.XXXXXX.log)
    container_data_file="/tmp/sedsuns-${table_name}-${file_name}"

    # CSV file CRLF to CR line ending fix
    podman exec sedsuns-oracle sh -c 'sed "s/\\r$//" "$1" > "$2"' sh \
      "/seed-data/$table_name/$file_name" "$container_data_file"

    if ! podman exec sedsuns-oracle sqlldr \
      "userid=SEDS_OLTP/$db_password@FREEPDB1" \
      "control=/load-control/$table_name.ctl" \
      "data=$container_data_file" \
      "log=/tmp/$file_name.log" \
      "bad=/tmp/$file_name.bad" \
      rows=10000 >"$load_log" 2>&1; then
      printf '\nSQL*Loader failed for %s:\n\n' "$data_file" >&2
      cat "$load_log" >&2
      podman exec sedsuns-oracle rm -f "$container_data_file"
      rm -f "$load_log"
      exit 1
    fi

    podman exec sedsuns-oracle rm -f "$container_data_file"
    rm -f "$load_log"
    completed_files=$((completed_files + 1))
    render_progress "$data_file"
  done
}

load_table grad
load_table biblioteka
load_table odeljenje
load_table tip_publikacije
load_table izdavac
load_table autor
load_table publikacija
load_table publikacija_autor
load_table primerak
load_table clan
load_table status_pozajmice
load_table pozajmica

printf '\nOLTP seed load completed successfully.\n'
