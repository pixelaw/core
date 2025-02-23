FROM ghcr.io/pixelaw/core:latest AS core


ENV STORAGE_DIR=/pixelaw/storage


RUN \
    unzip /pixelaw/storage_init/katana_db.zip -d /pixelaw/storage && \
    cd /pixelaw/contracts && \
    export WORLD_ADDRESS=$(jq -r '.world.address' manifest_dev.json) && \
    STORAGE_DIR=/pixelaw/storage scripts/populate.sh && \
    rm -rf /pixelaw/storage



