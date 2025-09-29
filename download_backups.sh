#!/usr/bin/env bash
set -euo pipefail

# Usage: ./download_backups.sh <s3-bucket-name>
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <s3-bucket-name>"
  exit 1
fi

BUCKET="$1"
OUTPUT_FILE="presign_urls.txt"

# 1) Get the most recent date directory under backups/
latest_date_dir=$(aws s3 ls "s3://$BUCKET/backups/" | awk '{print $2}' | sed 's:/$::' | sort | tail -n1)

if [[ -z "$latest_date_dir" ]]; then
  echo "No date directories found in s3://$BUCKET/backups/"
  exit 1
fi

echo "Latest date directory: $latest_date_dir"

# 2) Get the only subdirectory inside that date directory
first_subdir=$(aws s3 ls "s3://$BUCKET/backups/$latest_date_dir/" | awk '{print $2}' | sed 's:/$::')

if [[ -z "$first_subdir" ]]; then
  echo "No subdirectory found in s3://$BUCKET/backups/$latest_date_dir/"
  exit 1
fi

echo "First subdirectory: $first_subdir"

# 3) Define 'home' directory inside it
home_dir="home"

# 4) Iterate over each client directory under backups/<date>/<subdir>/home/
> "$OUTPUT_FILE"
aws s3 ls "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/" \
  | awk '{print $2}' | sed 's:/$::' | while read -r client_dir; do
  echo "Processing client: $client_dir"

  tar_path="backups/$latest_date_dir/$first_subdir/$home_dir/$client_dir/backup.tar"
  presign_url=$(aws s3 presign "s3://$BUCKET/$tar_path")

  echo "$presign_url"
  echo "$presign_url" >> "$OUTPUT_FILE"
done

echo "Presigned URLs saved to $OUTPUT_FILE"
