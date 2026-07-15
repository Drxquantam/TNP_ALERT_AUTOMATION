FROM alpine:3.24 AS python-build

RUN apk add --no-cache python3 py3-pip py3-virtualenv git gnupg




# Sparse-clone ONLY the Python task runner package (not the full 500MB repo)
RUN git clone \
      --depth 1 \
      --filter=blob:none \
      --no-checkout \
      --branch "n8n@2.28.5" \
      https://github.com/n8n-io/n8n.git \
      /tmp/n8n && \
    cd /tmp/n8n && \
    git sparse-checkout init --cone && \
    git sparse-checkout set "packages/@n8n/task-runner-python" && \
    git checkout

# Place runner at the exact hardcoded path n8n expects, build venv there
RUN mkdir -p /usr/local/lib/node_modules/@n8n && \
    cp -r /tmp/n8n/packages/@n8n/task-runner-python \
          /usr/local/lib/node_modules/@n8n/task-runner-python && \
    python3 -m venv /usr/local/lib/node_modules/@n8n/task-runner-python/.venv && \
    /usr/local/lib/node_modules/@n8n/task-runner-python/.venv/bin/pip install \
        --no-cache-dir \
        /usr/local/lib/node_modules/@n8n/task-runner-python && \
    /usr/local/lib/node_modules/@n8n/task-runner-python/.venv/bin/pip install \
        --no-cache-dir pandas numpy boto3 python-gnupg

FROM n8nio/n8n:latest

USER root

COPY --from=python-build /usr /usr
COPY --from=python-build /lib /lib

# Install openpgp in its own clean directory (avoids pnpm catalog conflict)
RUN mkdir -p /opt/custom-modules && \
    cd /opt/custom-modules && \
    npm init -y && \
    npm install openpgp

USER node
