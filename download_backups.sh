#!/usr/bin/env bash
set -euo pipefail

# Usage: ./download_backups.sh <source-s3-bucket>
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <s3-bucket>"
  exit 1
fi

# Bucket passed as argument
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

      # 5) Move (rename) backup.tar to home root as <client_dir>.tar
      aws s3 mv \
        "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/$client_dir/backup.tar" \
        "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/${client_dir}.tar"

      echo "Moved and renamed: ${client_dir}.tar"
    done

# 6) Remove all remaining subdirectories under home, leaving only .tar files
aws s3 rm "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/" \
  --recursive \
  --exclude "*.tar"

echo "Cleanup complete: only .tar files remain under home."
