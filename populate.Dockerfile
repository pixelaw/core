FROM ghcr.io/pixelaw/core:latest AS core


ENV STORAGE_DIR=/pixelaw/storage


RUN \
    unzip /pixelaw/storage_init/katana_db.zip -d /pixelaw/storage && \
    cd /pixelaw/contracts && \
    export DOJO_WORLD_ADDRESS=$(jq -r '.world.address' manifest_dev.json) && \
    STORAGE_DIR=/pixelaw/storage scripts/populate.sh && mv /pixelaw/storage/katana_db.zip /pixelaw/storage_init/ && \
    rm -rf /pixelaw/storage



