#!/bin/bash

# Optional env vars:
#   - PGPORT
#   - SLACK_WEBHOOK

# Required env vars:
required=(
  PGUSER
  PGPASSWORD
  PGHOST
  PREFIX
  BACKUP_PASSWORD
  S3_BUCKET
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_DEFAULT_REGION
)
for v in "${required[@]}"; do
  if [[ -z "${!v}" ]]; then
      echo "Required env var $v not set!"
      exit 1
  fi
done

# set variables
now=$(date +%Y%m%d-%H%M)
folder="backup"
filename="${PREFIX}_backup_${now}"
filepath="${folder}/${filename}"
upload=false
success=false

# dump db
mkdir -p $folder
pg_dumpall > "${filepath}.pgdump"
tar -zcf "${filepath}.tar.gz" -C backup "${filename}.pgdump" 
openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in "${filepath}.tar.gz" -out "${filepath}.tar.gz.enc" -pass "pass:$BACKUP_PASSWORD"

# check minimum filesize, to decide whether or not to upload
if [[ "$(stat -c %s ${filepath}.tar.gz.enc)" -gt 10 ]]; then
  upload=true
fi

# upload to s3
if [ "$upload" = true ]; then
  aws s3 cp "${filepath}.tar.gz.enc" $S3_BUCKET
  success=true
fi

# slack notification 
if [[ -n "${SLACK_WEBHOOK}" ]]; then
  if [ "$success" = true ]; then
    color="danger"
    msg="failed (${now})"
  else
    color="good"
    msg="successful (${now})"
  fi
  message="payload={\"attachments\":[{\"pretext\":\"*Postgres Backup: ${PREFIX}*\",\"text\":\"$msg\",\"color\":\"$color\"}]}"
  curl --silent -X POST --data-urlencode "$message" ${SLACK_WEBHOOK} > /dev/null
fi