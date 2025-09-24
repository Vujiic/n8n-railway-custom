# Debian baza (bookworm) umesto Alpine
FROM node:22-bookworm

# ---------- ARGS ----------
ARG N8N_VERSION=latest
ARG PGPASSWORD
ARG PGHOST
ARG PGPORT
ARG PGDATABASE
ARG PGUSER
ARG USERNAME
ARG PASSWORD
ARG ENCRYPTIONKEY

# ---------- ENV (kao kod tebe) ----------
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
# Bez volumena ćemo koristiti /data kao user folder u samom containeru
ENV N8N_USER_FOLDER=/data
ENV PYTHONUNBUFFERED=1

# ---------- OS paketi ----------
# python + toolchain (za prophet), graphicsmagick/tzdata kao i ranije
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-dev \
    build-essential gfortran \
    libopenblas-dev liblapack-dev \
    graphicsmagick tzdata bash git curl wget \
 && rm -rf /var/lib/apt/lists/*

# ---------- n8n ----------
RUN npm_config_user=root npm install --location=global n8n@${N8N_VERSION}

# ---------- Python venv + paketi ----------
RUN python3 -m venv /opt/py && \
    /opt/py/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/py/bin/pip install --no-cache-dir \
      numpy==1.26.4 \
      pandas==2.2.2 \
      scikit-learn==1.4.2 \
      prophet==1.1.5

# n8n Python (Beta) node -> koristi naš venv
ENV N8N_CODE_NODE_PYTHON_PATH=/opt/py/bin/python \
    N8N_CODE_NODE_PYTHON_ALLOW_GLOBAL=true

# pripremi /data (iako nema volume, treba write perms)
RUN mkdir -p /data && chown -R node:node /data

# ---------- Start ----------
USER node
WORKDIR /home/node
EXPOSE 5678
# Bind na 0.0.0.0 i Railway PORT (ako PORT nije postavljen, koristi 5678)
CMD ["bash","-lc","n8n start --host 0.0.0.0 --port ${PORT:-5678}"]
