#!/usr/bin/env bash

set -euo pipefail

# Doing logging stuff
LOG_FILE="$HOME/.config/ihub/error.log"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# figured some fancy colors would be nice
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$LOG_FILE"
}

info() {
    echo -e "[INFO] $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE"
}

success() { # this is most likely only used once or twice at the end of a script
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"
}

error_handler() { # couldn't think of a better way of trapping errors properly
    error "Command failed: $BASH_COMMAND (line $LINENO, exit code $?)"
}

trap error_handler ERR

info "Sending logs to $LOG_FILE"

if [ -f ~/.config/ihub/config.cfg ]; then
    ihub_home=$(awk '/^\[INSTALL_PATH\]/{getline; print; exit}' ~/.config/ihub/config.cfg)
else
    ihub_home="${IHUB_HOME:-$HOME/.ihub}"
    echo "No configuration file found. Defaulting to $ihub_home"
fi
uxplay_dir="$ihub_home/UxPlay"

if [[ ! -d "$uxplay_dir" ]]; then
	echo "UxPlay is not installed in $uxplay_dir."
	exit 1
fi

cd "$uxplay_dir"
sudo make uninstall

rm -rf "$uxplay_dir"

success "UxPlay uninstall complete"
