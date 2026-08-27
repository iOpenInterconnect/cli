#!/usr/bin/env bash

set -euo pipefail

error_handler() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Line $LINENO: $BASH_COMMAND" \
        >> "$HOME/.config/ihub/error.log"
}

trap error_handler ERR

# Updating dependencies

if [ -f ~/.config/ihub/config.cfg ]; then
    ihub_home=$(awk '/^\[INSTALL_PATH\]/{getline; print; exit}' ~/.config/ihub/config.cfg)
else
    ihub_home="${IHUB_HOME:-$HOME/.ihub}"
    echo "No configuration file found. Defaulting to $ihub_home"
fi


INSTALL="false"

read -p "Update dependencies? (y/n): " answer
case "$answer" in
    y|Y)
        INSTALL="true"
        ;;
    n|N)
        echo "Updating dependencies aborted."
        ;;
    *)
        echo "Invalid input. Update aborted."
        exit 1
        ;;
esac


if [ "$INSTALL" = "true" ]; then
    echo "Updating dependencies..."

    case "$(uname -s)" in
        FreeBSD)
            sudo pkg install -y git
            ;;
        OpenBSD)
            doas pkg_add git
            ;;
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Homebrew is not installed. Please install Homebrew first." | tee -a "$HOME/.config/ihub/error.log" >&2
                exit 1
            fi

            brew install git
            ;;
        Linux)
            if [[ ! -f /etc/os-release ]]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Unsupported Linux system: /etc/os-release was not found." | tee -a "$HOME/.config/ihub/error.log" >&2
                exit 1
            fi
            ;;
    esac

. /etc/os-release

case "${ID:-}" in
    debian|ubuntu|linuxmint|pop)
        distro_family=debian
        ;;

    fedora|rhel|centos|rocky|almalinux)
        distro_family=rpm
        ;;

    mageia)
        distro_family=mageia
        ;;

    pclinuxos)
        distro_family=pclinuxos
        ;;

    openmandriva)
        distro_family=openmandriva
        ;;

    opensuse*|sles)
        distro_family=opensuse
        ;;

    arch|manjaro|endeavouros)
        distro_family=arch
        ;;

    *)

        distro_family=

        for id_like in ${ID_LIKE:-}; do
            case "$id_like" in
                debian|ubuntu)
                    distro_family=debian
                    break
                    ;;

                fedora|rhel)
                    distro_family=rpm
                    break
                    ;;

                arch)
                    distro_family=arch
                    break
                    ;;

                mageia)
                    distro_family=mageia
                    break
                    ;;

                pclinuxos)
                    distro_family=pclinuxos
                    break
                    ;;

                openmandriva)
                    distro_family=openmandriva
                    break
                    ;;

                opensuse|sles)
                    distro_family=opensuse
                    break
                    ;;
            esac
        done
        ;;
esac

case "$distro_family" in
    debian)
        sudo apt update
        sudo apt install -y \
            git
        ;;

    rpm)
        sudo dnf install -y \
            git
        ;;

    mageia)
        sudo urpmi \
            git
        ;;

    pclinuxos)
        sudo apt-get update
        sudo apt-get install -y \
            git
        ;;

    openmandriva)
        sudo dnf install -y \
            git
        ;;

    opensuse)
        sudo zypper --non-interactive install \
            git
        ;;

    arch)
        sudo pacman -Syu --needed --noconfirm \
            git
        ;;

    *)
        echo "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}" >&2
        exit 1
        ;;
esac
fi

# Updating the cli

cd "$ihub_home/cli"
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [[ "$LOCAL" == "$REMOTE" ]]; then
    echo "CLI already up to date."
else
    echo "CLI update available:"
    git log --oneline "$LOCAL..$REMOTE"

    read -rp "Update now? (y/n): " answer

    case "$answer" in
    y|Y)
        git pull
        echo "CLI update complete."
        ;;
    *)
        echo "Update cancelled."
        ;;
    esac
fi

answer=skip

if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.bashrc"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
elif [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.zshrc"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
elif [[ -f "$HOME/.config/fish/config.fish" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.config/fish/config.fish"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
elif [[ -f "$HOME/.tcshrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.tcshrc"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
fi

case "$answer" in
    y|Y)
        echo "Exporting iHub to PATH..."
        export PATH="$PATH:$ihub_home/cli/core"
        if [[ -f "$HOME/.bashrc" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.bashrc"; then
                echo "export PATH=\"\$PATH:$ihub_home/cli/core\"" >> "$HOME/.bashrc"
                echo "Added iHub to PATH in .bashrc"
            else
                echo "iHub is already in PATH in .bashrc"
            fi
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.zshrc"; then
                echo "export PATH=\"\$PATH:$ihub_home/cli/core\"" >> "$HOME/.zshrc"
                echo "Added iHub to PATH in .zshrc"
            else
                echo "iHub is already in PATH in .zshrc"
            fi
        fi
        if [[ -f "$HOME/.config/fish/config.fish" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.config/fish/config.fish"; then
                echo "set -gx PATH \$PATH $ihub_home/cli/core" >> "$HOME/.config/fish/config.fish"
                echo "Added iHub to PATH in config.fish"
            else
                echo "iHub is already in PATH in config.fish"
            fi
        fi
        if [[ -f "$HOME/.tcshrc" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.tcshrc"; then
                echo "setenv PATH \$PATH:$ihub_home/cli/core" >> "$HOME/.tcshrc"
                echo "Added iHub to PATH in .tcshrc"
            else
                echo "iHub is already in PATH in .tcshrc"
            fi
        fi
        ;;
    n|N)
        echo "Skipping PATH export."
        echo "To use iHub, you can run it directly from the installation directory: ./$ihub_home/ihub"
        ;;
    skip)
        ;;
    *)
        echo "Invalid input. Skipping PATH export."
        ;;
esac

echo "Updating the projects..."

if [[ -f "$ihub_home/uxplay/update.sh" ]]; then
    . $ihub_home/uxplay/update.sh
else
    echo "ERROR: UxPlay update script not found"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: UxPlay update script not found" >> "$HOME/.config/ihub/error.log"
fi

echo "Update complete."
