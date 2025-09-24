FROM node:22-alpine

ARG N8N_VERSION=latest
ARG PGPASSWORD
ARG PGHOST
ARG PGPORT
ARG PGDATABASE
ARG PGUSER
ARG USERNAME
ARG PASSWORD
ARG ENCRYPTIONKEY

ENV N8N_ENCRYPTION_KEY=$ENCRYPTIONKEY
ENV DB_TYPE=postgresdb
ENV DB_POSTGRESDB_DATABASE=$PGDATABASE
ENV DB_POSTGRESDB_HOST=$PGHOST
ENV DB_POSTGRESDB_PORT=$PGPORT
ENV DB_POSTGRESDB_USER=$PGUSER
ENV DB_POSTGRESDB_PASSWORD=$PGPASSWORD
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=$USERNAME
ENV N8N_BASIC_AUTH_PASSWORD=$PASSWORD
ENV N8N_USER_ID=root

RUN apk add --no-cache \
    graphicsmagick tzdata bash git curl wget \
    python3 py3-pip py3-setuptools py3-virtualenv \
    build-base linux-headers gfortran \
    lapack-dev openblas-dev

RUN npm_config_user=root npm install --location=global n8n@${N8N_VERSION}

RUN python3 -m venv /opt/py && \
    /opt/py/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/py/bin/pip install --no-cache-dir \
      numpy==1.26.4 \
      pandas==2.2.2 \
      scikit-learn==1.4.2
RUN /opt/py/bin/pip install --no-cache-dir prophet==1.1.5

ENV N8N_CODE_NODE_PYTHON_PATH=/opt/py/bin/python \
    N8N_CODE_NODE_PYTHON_ALLOW_GLOBAL=true

WORKDIR /data
EXPOSE 5678

CMD sh -lc 'n8n start --host 0.0.0.0 --port ${PORT:-5678}'
