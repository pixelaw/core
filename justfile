# PixeLAW Core Justfile
#
# Docker Images:
#   just docker-build-base      Build base image (toolchain only)
#   just docker-build-core      Build core image (contracts migrated)
#   just docker-build-populated Build populated image (with pixel art)
#
# Development:
#   just up                     Start local environment (docker-compose)
#   just down                   Stop local environment
#   just build                  Build contracts
#   just test                   Run tests
#   just docker-test            Run tests using Docker (sozo 1.8.5)
#
# Deployment:
#   just deploy-sepolia         Deploy to Sepolia testnet
#   just deploy-slot NAME       Deploy to Cartridge Slot

set dotenv-load := true
set dotenv-path := "./.account"

# Repository configuration
repo := "ghcr.io/pixelaw/core"
base_repo := "ghcr.io/pixelaw/base"
core_version := `cat VERSION`
dojo_version := `cat DOJO_VERSION`
dojo_world_address := `cat DOJO_WORLD_ADDRESS`

# ==============================================================================
# Docker Image Builds
# ==============================================================================

# Build base image (Dojo toolchain only)
docker-build-base:
    docker build -f base.Dockerfile \
        -t {{ base_repo }}:{{ dojo_version }} \
        -t {{ base_repo }}:latest \
        --progress=plain .

# Build core image (contracts compiled and migrated)
docker-build-core:
    docker build \
        -t {{ repo }}:{{ core_version }} \
        -t {{ repo }}:latest \
        --secret id=DOJO_KEYSTORE_PASSWORD \
        --network=host \
        --progress=plain .

# Build populated image (with pixel art data)
docker-build-populated:
    docker build -f populate.Dockerfile \
        -t {{ repo }}:{{ core_version }}-populated \
        -t {{ repo }}:latest-populated \
        --network=host \
        --progress=plain .

# Build all images in sequence
docker-build-all: docker-build-base docker-build-core docker-build-populated

# ==============================================================================
# Docker Runtime
# ==============================================================================

# Start docker-compose services
up:
    docker compose up -d

# Stop docker-compose services
down:
    docker compose down

# View docker-compose logs
logs:
    docker compose logs -f

# Access running container shell
shell:
    docker compose exec pixelaw-core bash

# Run Docker container standalone (without docker-compose)
docker-run:
    docker run \
        --name pixelaw \
        --rm \
        -ti \
        -p 5050:5050 -p 8080:8080 \
        -e DOJO_WORLD_ADDRESS={{ dojo_world_address }} \
        -e WORLD_ID=local \
        -e RPC_URL=http://127.0.0.1:5050 \
        {{ repo }}:{{ core_version }}

# Run Docker container with bash shell
docker-bash:
    docker run \
        --name pixelaw \
        --rm \
        -ti \
        -p 5050:5050 -p 8080:8080 \
        -e DOJO_WORLD_ADDRESS={{ dojo_world_address }} \
        -e WORLD_ID=local \
        -e RPC_URL=http://127.0.0.1:5050 \
        {{ repo }}:{{ core_version }} \
        /bin/bash

# ==============================================================================
# Contract Development
# ==============================================================================

# Build contracts
build:
    cd contracts && scarb fmt && sozo build

# Run contract tests
test:
    cd contracts && scarb fmt && sozo test

# Run filtered contract tests
test_filtered filter:
    cd contracts && scarb fmt && sozo test --filter {{ filter }}

# Build contracts using Docker
docker-build-contracts:
    docker run --rm \
        --entrypoint sozo \
        -e HOME=/tmp \
        -v {{ justfile_directory() }}/contracts:/pixelaw/contracts \
        -v {{ justfile_directory() }}/pixelaw_test_utils:/pixelaw/pixelaw_test_utils \
        -w /pixelaw/contracts \
        {{ repo }}:latest \
        build

# Run contract tests using Docker
docker-test:
    docker run --rm \
        --entrypoint sozo \
        -e HOME=/tmp \
        -v {{ justfile_directory() }}/contracts:/pixelaw/contracts \
        -v {{ justfile_directory() }}/pixelaw_test_utils:/pixelaw/pixelaw_test_utils \
        -w /pixelaw/contracts \
        {{ repo }}:latest \
        test

# Run filtered contract tests using Docker
docker-test-filtered filter:
    docker run --rm \
        --entrypoint sozo \
        -e HOME=/tmp \
        -v {{ justfile_directory() }}/contracts:/pixelaw/contracts \
        -v {{ justfile_directory() }}/pixelaw_test_utils:/pixelaw/pixelaw_test_utils \
        -w /pixelaw/contracts \
        {{ repo }}:latest \
        test --filter {{ filter }}

# ==============================================================================
# Deployment
# ==============================================================================

# Deploy to Sepolia testnet
deploy-sepolia:
    scripts/deploy/sepolia.sh

# Deploy to Cartridge Slot
deploy-slot name:
    scripts/deploy/slot.sh {{ name }}

# ==============================================================================
# Claude Code
# ==============================================================================

claude:
    #!/usr/bin/env bash
    set -a
    source .claude.env
    set +a

    PROMPT=$(cat .claude.prompt)

    clear && claude \
      --dangerously-skip-permissions \
      --append-system-prompt "$PROMPT"

# Start tmux with 4 Claude Code panes (or reattach if exists)
claude4:
    #!/usr/bin/env bash
    SESSION="claude-4"

    # If session exists, just reattach
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "Reattaching to existing session..."
      tmux attach-session -t "$SESSION"
      exit 0
    fi

    # Create new session with first pane (100k line scrollback, mouse enabled)
    tmux new-session -d -s "$SESSION" -c "{{ justfile_directory() }}"
    tmux set-option -t "$SESSION" history-limit 100000
    tmux set-option -t "$SESSION" mouse on

    # Clean status bar showing full cwd
    tmux set-option -t "$SESSION" status-left ""
    tmux set-option -t "$SESSION" status-right " #{pane_current_path} "
    tmux set-option -t "$SESSION" status-right-length 100

    # Pane borders with numbers
    tmux set-option -t "$SESSION" pane-border-status top
    tmux set-option -t "$SESSION" pane-border-format " #{pane_index} "

    # Highlight active pane border
    tmux set-option -t "$SESSION" pane-active-border-style "fg=cyan,bold"

    # Alt+arrow to switch panes without prefix
    tmux bind-key -n M-Left select-pane -L
    tmux bind-key -n M-Right select-pane -R
    tmux bind-key -n M-Up select-pane -U
    tmux bind-key -n M-Down select-pane -D

    # Alt+z to zoom (fullscreen) current pane
    tmux bind-key -n M-z resize-pane -Z

    # Create 3 more panes
    tmux split-window -t "$SESSION" -c "{{ justfile_directory() }}"
    tmux split-window -t "$SESSION" -c "{{ justfile_directory() }}"
    tmux split-window -t "$SESSION" -c "{{ justfile_directory() }}"

    # Arrange as 2x2 grid
    tmux select-layout -t "$SESSION" tiled

    # Start claude in each pane
    for pane in 0 1 2 3; do
      tmux send-keys -t "$SESSION:0.$pane" "just claude" Enter
    done

    # Attach to session
    tmux attach-session -t "$SESSION"
