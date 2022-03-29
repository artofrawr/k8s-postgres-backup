FROM python:alpine3.15

WORKDIR /workspace

RUN apk --update --no-cache add bash postgresql curl openssl
RUN pip install awscli

COPY backup.sh ./
RUN chmod +x ./backup.sh
