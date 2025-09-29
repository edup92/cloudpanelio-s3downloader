#!/usr/bin/env bash
set -euo pipefail

# Comprueba que nos pasan el nombre de la repo
if [ $# -lt 1 ]; then
  echo "Usage: $0 <repo-name>"
  exit 1
fi

REPO="$1"
BUCKET="tu-bucket-s3"

# 1) Obtener la carpeta de fecha más reciente en backups/
latest_date_dir=$(aws s3 ls s3://"$BUCKET"/backups/ \
  | awk '{print $2}' \
  | sed 's:/$::' \
  | sort \
  | tail -n1)

echo "Latest date directory: $latest_date_dir"

# 2) Definir la carpeta de la repo pasada como argumento
echo "Using repo directory: $REPO"

# 3) Fijar la ruta hasta home dentro de esa repo
base_path="s3://$BUCKET/backups/$latest_date_dir/$REPO/home"

# 4) Recorrer cada carpeta cliente dentro de home/
aws s3 ls "$base_path"/ \
  | awk '{print $2}' \
  | sed 's:/$::' \
  | while read -r client_dir; do
      echo "Processing client: $client_dir"

      # 5) Descargar backup.tar y renombrarlo a <client_dir>.tar
      aws s3 cp \
        "$base_path/$client_dir/backup.tar" \
        "./${client_dir}.tar"

      echo "Downloaded and renamed: ${client_dir}.tar"
    done

echo "All backups downloaded."
