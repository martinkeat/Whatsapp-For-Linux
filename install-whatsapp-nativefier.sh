#!/usr/bin/env bash
# Universal WhatsApp-for-Linux Installer
# Author: spontaneocus (aka Martin J. Keatings)
# URL: https://github.com/martinkeat/Whatsapp-For-Linux/blob/main/install-whatsapp-nativefier.sh

set -Eeuo pipefail

# =========================
# UI helpers
# =========================
bold() { printf "\e[1m%s\e[0m" "$*"; }
box() {
  local msg="$1"
  local width="${COLUMNS:-80}"
  local line
  line=$(printf '%*s' "$width" '' | tr ' ' '=')
  echo
  echo -e "$(bold "$line")"
  # center message if shorter than line
  local pad=$(( (width - ${#msg}) / 2 ))
  if (( pad > 0 )); then
    printf "\e[1m%*s%s%*s\e[0m\n" "$pad" "" "$msg" "$pad" ""
  else
    echo -e "$(bold "$msg")"
  fi
  echo -e "$(bold "$line")"
}
ok()   { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
die()  { echo "❌ $*" >&2; exit 1; }

trap 'echo; box "An error occurred. See messages above."; exit 1' ERR

# =========================
# Detect distro and pkg mgr
# =========================
ID_LIKE_LOWER=""
DISTRO_ID="unknown"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID:-unknown}"
  ID_LIKE_LOWER="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
fi

PM=""
INSTALL_CMD=""
REFRESH_CMD=""

case "$DISTRO_ID" in
  debian|ubuntu|raspbian|linuxmint|elementary|pop|zorin|neon|kali)
    PM="apt-get"
    REFRESH_CMD="apt-get update -y"
    INSTALL_CMD="apt-get install -y"
    ;;
  fedora|rhel|centos|rocky|almalinux|ol)
    PM="dnf"
    REFRESH_CMD="dnf -y makecache"
    INSTALL_CMD="dnf -y install"
    ;;
  arch|manjaro|endeavouros|arco*)
    PM="pacman"
    REFRESH_CMD="pacman -Sy --noconfirm"
    INSTALL_CMD="pacman -S --noconfirm --needed"
    ;;
  opensuse*|suse|sles|leap|tumbleweed)
    PM="zypper"
    REFRESH_CMD="zypper --non-interactive refresh"
    INSTALL_CMD="zypper --non-interactive install --no-recommends"
    ;;
  alpine)
    PM="apk"
    REFRESH_CMD="apk update"
    INSTALL_CMD="apk add --no-cache"
    ;;
  gentoo)
    PM="emerge"
    REFRESH_CMD="true"
    INSTALL_CMD="emerge --quiet --update --newuse"
    ;;
  *)
    # Try ID_LIKE families
    if [[ "$ID_LIKE_LOWER" == *debian* || "$ID_LIKE_LOWER" == *ubuntu* ]]; then
      PM="apt-get"; REFRESH_CMD="apt-get update -y"; INSTALL_CMD="apt-get install -y"
    elif [[ "$ID_LIKE_LOWER" == *rhel* || "$ID_LIKE_LOWER" == *fedora* || "$ID_LIKE_LOWER" == *centos* ]]; then
      PM="dnf"; REFRESH_CMD="dnf -y makecache"; INSTALL_CMD="dnf -y install"
    elif [[ "$ID_LIKE_LOWER" == *suse* ]]; then
      PM="zypper"; REFRESH_CMD="zypper --non-interactive refresh"; INSTALL_CMD="zypper --non-interactive install --no-recommends"
    elif [[ "$ID_LIKE_LOWER" == *arch* ]]; then
      PM="pacman"; REFRESH_CMD="pacman -Sy --noconfirm"; INSTALL_CMD="pacman -S --noconfirm --needed"
    else
      die "Unsupported or unrecognized Linux distribution. Please install Node.js, npm, curl, git, and nativefier manually."
    fi
    ;;
esac

SUDO=""
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
fi

# =========================
# Choose arch for Nativefier
# =========================
UNAME_M="$(uname -m)"
N_ARCH="x64"
case "$UNAME_M" in
  x86_64|amd64) N_ARCH="x64" ;;
  i386|i686)    N_ARCH="ia32" ;;
  aarch64|arm64) N_ARCH="arm64" ;;
  armv7l|armv7|armhf) N_ARCH="armv7l" ;;
  mips64el)     N_ARCH="mips64el" ;;
  *)            N_ARCH="x64" ;; # fallback
esac

# =========================
# Install deps
# =========================
box "Installing system dependencies..."
# Refresh repos (where meaningful)
$SUDO bash -lc "$REFRESH_CMD" || warn "Repo refresh failed (continuing anyway)."

# Map packages per family
DEPS_COMMON=(curl git nodejs npm)
DEPS_XVFB=() # will add later if headless setup chosen, but include now as harmless
case "$PM" in
  apt-get)
    DEPS_XVFB=(xvfb xvfb-run)
    $SUDO $INSTALL_CMD "${DEPS_COMMON[@]}" || die "Failed to install base deps."
    $SUDO $INSTALL_CMD "${DEPS_XVFB[@]}" || warn "Failed to install Xvfb helpers (non-fatal)."
    ;;
  dnf)
    DEPS_XVFB=(xorg-x11-server-Xvfb)
    $SUDO $INSTALL_CMD "${DEPS_COMMON[@]}" || die "Failed to install base deps."
    $SUDO $INSTALL_CMD "${DEPS_XVFB[@]}" || warn "Failed to install Xvfb (non-fatal)."
    ;;
  pacman)
    DEPS_XVFB=(xorg-server-xvfb)
    $SUDO $INSTALL_CMD "${DEPS_COMMON[@]}" || die "Failed to install base deps."
    $SUDO $INSTALL_CMD "${DEPS_XVFB[@]}" || warn "Failed to install Xvfb (non-fatal)."
    ;;
  zypper)
    DEPS_XVFB=(xorg-x11-server-Xvfb)
    $SUDO $INSTALL_CMD "${DEPS_COMMON[@]}" || die "Failed to install base deps."
    $SUDO $INSTALL_CMD "${DEPS_XVFB[@]}" || warn "Failed to install Xvfb (non-fatal)."
    ;;
  apk)
    DEPS_XVFB=(xvfb xvfb-run)
    $SUDO $INSTALL_CMD "${DEPS_COMMON[@]}" || die "Failed to install base deps."
    $SUDO $INSTALL_CMD "${DEPS_XVFB[@]}" || warn "Failed to install Xvfb (non-fatal)."
    ;;
  emerge)
    # Gentoo users typically manage USE flags; attempt generic installs
    $SUDO $INSTALL_CMD dev-vcs/git net-misc/curl net-libs/nodejs || warn "Install base deps manually on Gentoo if this fails."
    # Xvfb provided by xorg-server with proper USE flags
    ;;
esac

command -v node >/dev/null 2>&1 || die "Node.js not available after install."
command -v npm  >/dev/null 2>&1 || die "npm not available after install."

# =========================
# Nativefier install
# =========================
box "Installing Nativefier (npm)..."
if command -v nativefier >/dev/null 2>&1; then
  ok "Nativefier already installed."
else
  $SUDO npm install -g nativefier || die "Failed to install Nativefier via npm."
fi

# =========================
# Build app with Nativefier
# =========================
APP_NAME="whatsapp-for-linux"
TARGET_URL="https://web.whatsapp.com"

# Install location
if [[ $EUID -eq 0 ]]; then
  INSTALL_DIR="/opt/WhatsApp"
else
  INSTALL_DIR="$HOME/.local/share/nativefier/WhatsApp"
fi
$SUDO mkdir -p "$INSTALL_DIR"

box "Building WhatsApp desktop application with Nativefier..."
BUILD_PARENT="$(mktemp -d)"
# Use --out to control parent dir, Nativefier creates a subdir inside
nativefier \
  --name "$APP_NAME" \
  --platform linux \
  --arch "$N_ARCH" \
  --single-instance \
  --tray \
  --disable-dev-tools \
  --fast-quit \
  --internal-urls ".*" \
  "$TARGET_URL" \
  --out "$BUILD_PARENT" \
  || die "Nativefier build failed."

# Find the created app directory: ${APP_NAME}-linux-<arch>*
APP_DIR="$(find "$BUILD_PARENT" -maxdepth 1 -type d -name "${APP_NAME}-linux-*${N_ARCH}*" -print -quit)"
# Some nativefier versions omit arch suffix ordering; fallback: any ${APP_NAME}-linux-*
if [[ -z "${APP_DIR:-}" ]]; then
  APP_DIR="$(find "$BUILD_PARENT" -maxdepth 1 -type d -name "${APP_NAME}-linux-*" -print -quit)"
fi
[[ -n "${APP_DIR:-}" ]] || die "Could not locate Nativefier output directory."

# Move into INSTALL_DIR (clean existing safely)
if [[ -d "$INSTALL_DIR" && -n "$(ls -A "$INSTALL_DIR" 2>/dev/null || true)" ]]; then
  TS="$(date +%Y%m%d%H%M%S)"
  $SUDO mv "$INSTALL_DIR" "${INSTALL_DIR}.bak_${TS}" || true
  $SUDO mkdir -p "$INSTALL_DIR"
fi
$SUDO cp -a "$APP_DIR"/. "$INSTALL_DIR"/ || die "Failed to copy app into $INSTALL_DIR"
rm -rf "$BUILD_PARENT"

# Ensure binary exists and is executable
if [[ -f "$INSTALL_DIR/$APP_NAME" ]]; then
  $SUDO chmod +x "$INSTALL_DIR/$APP_NAME"
else
  # Some builds name the binary without hyphens or with capital letters—normalize
  BIN_CANDIDATE="$(find "$INSTALL_DIR" -maxdepth 1 -type f -perm -111 | head -n1 || true)"
  [[ -n "$BIN_CANDIDATE" ]] || die "Executable not found in $INSTALL_DIR."
  $SUDO mv "$BIN_CANDIDATE" "$INSTALL_DIR/$APP_NAME"
  $SUDO chmod +x "$INSTALL_DIR/$APP_NAME"
fi

# Symlink for system-wide CLI
if [[ $EUID -eq 0 ]]; then
  $SUDO ln -sf "$INSTALL_DIR/$APP_NAME" /usr/local/bin/$APP_NAME
else
  mkdir -p "$HOME/.local/bin"
  ln -sf "$INSTALL_DIR/$APP_NAME" "$HOME/.local/bin/$APP_NAME"
  # Add to PATH for current session if needed
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) :;;
    *) export PATH="$HOME/.local/bin:$PATH";;
  esac
fi

# =========================
# Desktop launcher
# =========================
box "Creating desktop launcher entry..."
LAUNCHER_DIR="$HOME/.local/share/applications"
mkdir -p "$LAUNCHER_DIR"
DESKTOP_FILE="$LAUNCHER_DIR/${APP_NAME}.desktop"

# Pick an icon if nativefier grabbed one; else leave a generic name
ICON_PATH="$(find "$INSTALL_DIR" -maxdepth 2 -type f \( -name '*.png' -o -name '*.ico' \) | head -n1 || true)"
if [[ -z "$ICON_PATH" ]]; then
  ICON_PATH="whatsapp" # rely on system theme fallback
fi

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=WhatsApp
Comment=Unofficial WhatsApp Web desktop app (Nativefier)
Exec=${INSTALL_DIR}/${APP_NAME} %u
Icon=${ICON_PATH}
Terminal=false
Type=Application
Categories=Network;Chat;InstantMessaging;
StartupWMClass=${APP_NAME}
EOF

# Refresh desktop entries if tool available
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$LAUNCHER_DIR" || true

# =========================
# Autostart prompt
# =========================
echo
read -r -p "Enable autostart so WhatsApp launches on login? [y/N]: " AUTOSTART
if [[ "${AUTOSTART,,}" == "y" || "${AUTOSTART,,}" == "yes" ]]; then
  AUTOSTART_DIR="$HOME/.config/autostart"
  mkdir -p "$AUTOSTART_DIR"
  cp -f "$DESKTOP_FILE" "$AUTOSTART_DIR/${APP_NAME}.desktop"
  # Ensure GNOME honors it
  if ! grep -q "^X-GNOME-Autostart-enabled=" "$AUTOSTART_DIR/${APP_NAME}.desktop" 2>/dev/null; then
    echo "X-GNOME-Autostart-enabled=true" >> "$AUTOSTART_DIR/${APP_NAME}.desktop"
  fi
  ok "Autostart enabled."
else
  warn "Autostart not enabled."
fi

# =========================
# Headless offer if no GUI
# =========================
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  echo
  warn "No graphical display detected."
  read -r -p "Configure headless mode (Xvfb + systemd) to keep WhatsApp running in background? [y/N]: " HEADLESS
  if [[ "${HEADLESS,,}" == "y" || "${HEADLESS,,}" == "yes" ]]; then
    box "Configuring headless service (Xvfb)..."
    # Ensure Xvfb present (second attempt per family)
    case "$PM" in
      apt-get) $SUDO $INSTALL_CMD xvfb xvfb-run || true ;;
      dnf)     $SUDO $INSTALL_CMD xorg-x11-server-Xvfb || true ;;
      pacman)  $SUDO $INSTALL_CMD xorg-server-xvfb || true ;;
      zypper)  $SUDO $INSTALL_CMD xorg-x11-server-Xvfb || true ;;
      apk)     $SUDO $INSTALL_CMD xvfb xvfb-run || true ;;
      emerge)  : ;; # assume managed by admin
    esac

    SERVICE_PATH="/etc/systemd/system/${APP_NAME}.service"
    $SUDO bash -c "cat > '$SERVICE_PATH'" <<'EOSVC'
[Unit]
Description=WhatsApp for Linux (Headless)
After=network.target

[Service]
Type=simple
User=__USER__
Environment=DISPLAY=:99
ExecStart=/usr/bin/xvfb-run -a -s "-screen 0 1280x720x24" __INSTALL__/__APPNAME__
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOSVC
    # Replace tokens
    $SUDO sed -i "s|__USER__|$USER|g" "$SERVICE_PATH"
    $SUDO sed -i "s|__INSTALL__|$INSTALL_DIR|g" "$SERVICE_PATH"
    $SUDO sed -i "s|__APPNAME__|$APP_NAME|g" "$SERVICE_PATH"

    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now "$APP_NAME.service" || warn "Could not start headless service; check logs."
    ok "Headless service installed. Check: sudo systemctl status ${APP_NAME}"
    warn "Remember: perform initial QR login once in a GUI (or via VNC to the Xvfb display)."
  fi
fi

# =========================
# Done
# =========================
box "Installation complete!"
echo -e "Launch via: $(bold $APP_NAME)  or find 'WhatsApp' in your app menu."
echo -e "If you find this useful, consider supporting: $(bold https://paypal.me/spontaneocus)"
