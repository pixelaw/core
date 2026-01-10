################################################################################
# PixeLAW Populated Dockerfile
#
# Extends the core image with pre-populated pixel art data.
# Used for demos and testing environments.
#
# Build: docker build -f populate.Dockerfile -t ghcr.io/pixelaw/core-populated .
################################################################################

FROM ghcr.io/pixelaw/core:latest

# Copy build scripts and contracts (needed for sozo execute)
COPY ./scripts /pixelaw/scripts
COPY ./contracts /pixelaw/contracts
COPY ./pixelaw_test_utils /pixelaw/pixelaw_test_utils

ENV STORAGE_DIR=/pixelaw/storage

# Run populate script to add pixel art data
RUN bash /pixelaw/scripts/docker/build-populated.sh dev

# Clean up build artifacts from runtime image
RUN rm -rf /pixelaw/scripts /pixelaw/contracts /pixelaw/pixelaw_test_utils
