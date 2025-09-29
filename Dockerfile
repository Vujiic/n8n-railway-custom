# ---------------------------------------------------
# Base: Debian (bookworm), ne koristimo Alpine/apk
# ---------------------------------------------------
FROM node:22-bookworm

# ---------- OS paketi ----------
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-dev \
    build-essential gfortran \
    libopenblas-dev liblapack-dev \
    graphicsmagick tzdata bash git curl wget \
 && rm -rf /var/lib/apt/lists/*

# ---------- n8n ----------
ARG N8N_VERSION=latest
RUN npm_config_user=root npm install --location=global n8n@${N8N_VERSION}

# ---------- Python venv + paketi ----------
RUN python3 -m venv /opt/py && \
    /opt/py/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/py/bin/pip install --no-cache-dir \
      numpy==1.26.4 \
      pandas==2.2.2 \
      scikit-learn==1.4.2 \
      prophet==1.1.5 \
      tensorflow==2.15.0

# n8n Python (Beta) node -> koristi naš venv
ENV N8N_CODE_NODE_PYTHON_PATH=/opt/py/bin/python \
    N8N_CODE_NODE_PYTHON_ALLOW_GLOBAL=true

# n8n opšta podešavanja
ENV N8N_USER_FOLDER=/data \
    PYTHONUNBUFFERED=1 \
    N8N_DIAGNOSTICS_ENABLED=false

# pripremi /data i dozvole
RUN mkdir -p /data && chown -R node:node /data

# ---------- Entrypoint ----------
# fajl stoji pored Dockerfile-a u repo-u
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER node
WORKDIR /home/node
EXPOSE 5678

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["n8n", "start", "--host", "0.0.0.0"]
