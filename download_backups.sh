#!/usr/bin/env bash
set -euo pipefail

# Usage: ./generate_presign_urls.sh <s3-bucket-name>

if [[ $# -lt 1 ]]; then
echo "Usage: $0 <s3-bucket-name>"
exit 1
fi

BUCKET="$1"
OUTPUT_FILE="presign_urls.txt"

# 1) Find the most recent date directory under backups/

latest_date_dir=$(aws s3 ls "s3://$BUCKET/backups/" 
| awk '{print $2}' | sed 's:/$::' | sort | tail -n1)

if [[ -z "$latest_date_dir" ]]; then
echo "No date directories found in s3://$BUCKET/backups/"
exit 1
fi

echo "Latest date directory: $latest_date_dir"

# 2) Identify the only subdirectory under that date

first_subdir=$(aws s3 ls "s3://$BUCKET/backups/$latest_date_dir/" 
| awk '{print $2}' | sed 's:/$::')

echo "First subdirectory: $first_subdir"

# 3) Set home directory

home_dir="home"

# 4) List all backup.tar files under the path

keys=$(aws s3 ls "s3://$BUCKET/backups/$latest_date_dir/$first_subdir/$home_dir/" 
--recursive | awk '{print $4}' | grep 'backup.tar$')

# 5) Generate presigned URLs

echo "Generating presigned URLs into $OUTPUT_FILE"
: > "$OUTPUT_FILE"
for key in $keys; do
presign=$(aws s3 presign "s3://$BUCKET/$key")
echo "$presign" >> "$OUTPUT_FILE"
done

echo "Done. Presigned URLs saved to $OUTPUT_FILE"
