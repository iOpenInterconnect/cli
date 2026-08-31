echo "Welcome to the iHub installer"
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

ihub_home="${IHUB_HOME:-$HOME/.ihub}"
INSTALL="false"

read -p "Continue installing iHub? (y/n): " answer
case "$answer" in
    y|Y)
        echo "Installing iHub..."
        INSTALL="true"
        ;;
    n|N)
        echo "Installation aborted."
        exit 0
        ;;
    *)
        echo "Invalid input. Installation aborted."
        exit 1
        ;;
esac


if [ "$INSTALL" = "true" ]; then
    echo "Installing dependencies..."

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
;;
esac

mkdir -p ~/.config/ihub/
touch ~/.config/ihub/config.cfg

read -p "Enter install path (default ~/.ihub): " input
ihub_home="${input:-$ihub_home}"

echo "[INSTALL_PATH]" >> ~/.config/ihub/config.cfg
echo $ihub_home >> ~/.config/ihub/config.cfg

mkdir -p "${ihub_home:-$HOME/.ihub}"

cd "$ihub_home"

git clone -b main --single-branch --depth 1 https://github.com/iOpenInterconnect/cli.git

read -p "Export iHub to PATH? (recommended) (y/n): " answer
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
    *)
        echo "Invalid input. Skipping PATH export."
        ;;
esac
fi