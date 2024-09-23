#!/bin/bash

# Katanaを新しいタブで起動
osascript <<EOF
tell application "Terminal"
    activate
    tell application "System Events" to keystroke "t" using {command down}
    do script "katana --disable-fee --allowed-origins '*' --db-dir katana" in front window
end tell
EOF

# Toriiを別の新しいタブで起動
osascript <<EOF
tell application "Terminal"
    activate
    tell application "System Events" to keystroke "t" using {command down}
    do script "torii --world 0x263ae44e5414519a5c5a135cccaf3d9d7ee196d37e8de47a178da91f3de9b34 --allowed-origins '*'" in front window
end tell
EOF
