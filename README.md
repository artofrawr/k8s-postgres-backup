# k8s-postgres-backup

A Kubernetes cronjob to back up a Postgres db and upload it to S3.  
Optional notification via Slack webhook.

### To decode a backup file

```
openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in <encodedfile> -out db.pgdump.tar.gz
```
