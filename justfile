# Load environment variables from ./.account

set dotenv-load := true
set dotenv-path := "./.account"

# Repository configuration

repo := "ghcr.io/pixelaw/core"
core_version := `cat VERSION`
dojo_version := `cat DOJO_VERSION`
dojo_world_address := `cat DOJO_WORLD_ADDRESS`

claude:
    #!/usr/bin/env bash
    set -a
    source .claude.env
    set +a

    PROMPT=$(cat .claude.prompt)

    clear && claude \
      --dangerously-skip-permissions \
      --append-system-prompt "$PROMPT"

# Build Docker image with populated data
docker-build-populate:
    @echo $private_key
    docker build -f populate.Dockerfile -t {{ repo }}:{{ core_version }}-populated \
        --build-arg DOJO_VERSION={{ dojo_version }} \
        --build-arg GENERATE_POPULATED_CORE=false \
        --secret id=DOJO_KEYSTORE_PASSWORD \
        --network=host \
        --pull=false \
        --progress=plain .

# Build Docker image
docker-build:
    @echo $private_key
    docker build -t {{ repo }}:{{ core_version }} -t {{ repo }}:latest \
        --build-arg DOJO_VERSION={{ dojo_version }} \
        --build-arg GENERATE_POPULATED_CORE=false \
        --secret id=DOJO_KEYSTORE_PASSWORD \
        --network=host \
        --pull=false \
        --progress=plain .

# Run Docker container with default ports
docker-run:
    docker run \
        --name pixelaw \
        --rm \
        -ti \
        -p 3000:3000 -p 5050:5050 -p 8080:8080 \
        -e DOJO_WORLD_ADDRESS={{ dojo_world_address }} \
        -e SERVER_PORT=3000 \
        {{ repo }}:{{ core_version }}

# Run Docker container with bash shell
docker-bash:
    docker run \
        --name pixelaw \
        --rm \
        -ti \
        -p 3000:3000 -p 5050:5050 -p 8080:8080 \
        -e DOJO_WORLD_ADDRESS={{ dojo_world_address }} \
        -e SERVER_PORT=3000 \
        {{ repo }}:{{ core_version }} \
        /bin/bash

# Build contracts
build:
    cd contracts && scarb fmt && sozo build

# Access running Keiko container shell
shell:
    docker compose exec keiko bash

# Run contract tests
test:
    cd contracts && scarb fmt && sozo test

# Run filtered contract tests
test_filtered filter:
    cd contracts && scarb fmt && sozo test --filter {{ filter }}

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
