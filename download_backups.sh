#!/usr/bin/env bash
set -euo pipefail

# Usage: ./download_backups.sh <s3-bucket-name>
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <s3-bucket-name>"
  exit 1
fi

# Bucket passed as first argument
BUCKET="$1"

# 1) Get the most recent date directory in backups/
latest_date_dir=$(aws s3 ls "s3://$BUCKET/backups/" \
  | awk '{print $2}' \
  | sed 's:/$::' \
  | sort \
  | tail -n1)

if [[ -z "$latest_date_dir" ]]; then
  echo "No date directories found in s3://$BUCKET/backups/"
  exit 1
fi

echo "Latest date directory: $latest_date_dir"

# 2) Get the only subdirectory inside that date directory
first_subdir=$(aws s3 ls "s3://$BUCKET/backups/$latest_date_dir/" \
  | awk '{print $2}' \
  | sed 's:/$::')

echo "First subdirectory: $first_subdir"

# 3) Define the "home" directory inside of it
home_dir="home"

# 4) Iterate over each client directory under backups/<date>/<subdir>/home/
aws s3 ls "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/" \
  | awk '{print $2}' \
  | sed 's:/$::' \
  | while read -r client_dir; do
      echo "Processing client: $client_dir"

      # 5) Download backup.tar and rename it to <client_dir>.tar
      aws s3 cp \
        "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/$client_dir/backup.tar" \
        "${client_dir}.tar"

      echo "Downloaded and renamed: ${client_dir}.tar"
    done

echo "All backups downloaded to $(pwd)"
