#!/usr/bin/env bash

error_handler() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Line $LINENO: $BASH_COMMAND" \
        >> "$HOME/.config/ihub/error.log"
}

trap error_handler ERR

ihub_home="${IHUB_HOME:-${HOME}/.ihub}"
uxplay_dir="$ihub_home/UxPlay"

if [[ ! -d "$uxplay_dir" ]]; then
	echo "UxPlay is not installed in $uxplay_dir."
	exit 1
fi

cd "$uxplay_dir"
sudo make uninstall

rm -rf "$uxplay_dir"
