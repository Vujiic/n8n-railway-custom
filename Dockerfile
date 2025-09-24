FROM node:22-alpine

# ====== n8n env koje već imaš ======
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

# ====== OS paketi ======
# graphicsmagick/tzdata (kao pre) + Python + build alati + fortran (za Prophet), lapack/openblas
RUN apk add --no-cache \
    graphicsmagick tzdata bash git curl wget \
    python3 py3-pip py3-setuptools py3-virtualenv \
    build-base linux-headers gfortran \
    lapack-dev openblas-dev

# ====== (opciono) glibc kompat sloj da bi TensorFlow wheel mogao da radi na Alpine ======
# Ako ti build pukne na nekom od narednih koraka, PROBAJ prvo da izostaviš ovaj blok i/ili TF.
ENV GLIBC_VERSION=2.35-r1
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk && \
    apk add --no-cache glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk && \
    rm -f glibc-*.apk

# ====== n8n instalacija (kao kod tebe) ======
RUN npm_config_user=root npm install --location=global n8n@${N8N_VERSION}

# ====== Python venv + paketi ======
# Kreiramo izolovani venv (PEP 668 safe), instaliramo tipične ML libove.
# TensorFlow na Alpine je tricky; ovaj korak MOŽE da padne. Ako se desi — vidi napomene ispod.
RUN python3 -m venv /opt/py && \
    /opt/py/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/py/bin/pip install --no-cache-dir \
      numpy==1.26.4 \
      pandas==2.2.2 \
      scikit-learn==1.4.2 && \
    /opt/py/bin/pip install --no-cache-dir \
      tensorflow-cpu==2.15.0 || echo "TensorFlow install failed on Alpine (continuing without TF)"

# Ako želiš Prophet (opciono; često radi na Alpine uz gfortran/openblas):
# RUN /opt/py/bin/pip install --no-cache-dir prophet==1.1.5

# ====== Recimo n8n Python (Beta) nodu da koristi naš venv ======
ENV N8N_CODE_NODE_PYTHON_PATH=/opt/py/bin/python \
    N8N_CODE_NODE_PYTHON_ALLOW_GLOBAL=true

# ====== Radni dir i portovi ======
WORKDIR /data
EXPOSE 5678

# ====== Start n8n ======
# Varijanta A (minimal change, kao kod tebe + bind na sve interfejse):
CMD sh -lc 'export N8N_PORT=${PORT:-5678}; n8n start --host 0.0.0.0 --port "$N8N_PORT"'
